const { AsyncLocalStorage } = require('node:async_hooks');
const { createHash, randomBytes } = require('node:crypto');
const { ObjectId } = require('mongodb');

const writes = new AsyncLocalStorage();
const digest = value => createHash('sha256').update(value).digest('hex');
const failure = (message, status = 400) => Object.assign(new Error(message), { status });

function readCoordinate(record, keys) {
    for (const key of keys) {
        const raw = record[key];
        if (raw == null || String(raw).trim() === '' || String(raw).trim().toLowerCase() === 'null') continue;
        const value = Number(String(raw).trim().replace(',', '.'));
        if (!Number.isNaN(value)) return value;
    }
    return NaN;
}

// Helpers called by an order/payment handler participate in the same session.
function transactionalCollection(collection) {
    const optionPositions = { find: 1, findOne: 1, insertOne: 1, insertMany: 1,
        updateOne: 2, updateMany: 2, deleteOne: 1, deleteMany: 1, bulkWrite: 1,
        findOneAndUpdate: 2, countDocuments: 1, aggregate: 1 };
    return new Proxy(collection, { get(target, property) {
        const value = target[property];
        if (typeof value !== 'function') return value;
        return (...args) => {
            const context = writes.getStore();
            const index = optionPositions[property];
            if (context?.session && index !== undefined) {
                args[index] = { ...args[index], session: context.session };
            }
            return value.apply(target, args);
        };
    } });
}

function paymentBalance(total, paid) {
    total = Number(total);
    paid = Number(paid ?? 0);
    if (!Number.isFinite(total) || total < 0 || !Number.isFinite(paid) || paid < 0 || paid > total) {
        throw failure('Invalid order total or paid amount');
    }
    return { paidAmount: paid, dueAmount: total - paid,
        payment_status: paid >= total ? 'paid' : paid > 0 ? 'partial' : 'pending' };
}

function stockQuantity(item) {
    const quantity = Number(item.quantity ?? item.qty ?? 0);
    const free = Number(item.freeQty ?? item.free_qty ?? 0);
    if (!Number.isSafeInteger(quantity) || quantity < 0 || !Number.isSafeInteger(free) || free < 0) {
        throw failure('Item quantities must be non-negative whole numbers');
    }
    // Preserve the existing stock unit convention: freeQty is separate.
    return quantity;
}

async function adjustStock(products, items, distributorId, restore = false) {
    if (!distributorId) throw failure('Distributor is required');
    for (const item of items) {
        const quantity = stockQuantity(item);
        if (!quantity) continue;
        const id = item.productId || item.product_id;
        const identity = id && ObjectId.isValid(id) ? { _id: new ObjectId(id) } : { sku: item.sku };
        if (!identity._id && !identity.sku) throw failure('Product identity is required');
        const tenant = { $or: [{ distributorId }, { distributor_id: distributorId }] };
        const filter = { ...identity, ...tenant, ...(!restore ? { stock: { $gte: quantity } } : {}) };
        const result = await products.updateOne(filter, {
            $inc: { stock: restore ? quantity : -quantity },
            $set: { updatedAt: new Date().toISOString() }
        });
        if (result.matchedCount !== 1) throw failure('Product is unavailable or has insufficient stock', 409);
    }
}

function reliableWrite(getClient, getDb, handler) {
    return async (req, res) => {
        const key = String(req.get('Idempotency-Key') || '').trim();
        if (key.length > 200) return res.status(400).json({ error: 'Invalid idempotency key' });
        if (req.auth?.role === 'salesman' && req.method === 'POST' && !key) {
            return res.status(400).json({ error: 'A retry key is required for this write' });
        }
        const body = structuredClone(req.body);
        const actor = String(req.auth?._id || '');
        const receiptId = key ? digest(`${actor}|${req.method}|${req.originalUrl}|${key}`) : null;
        const canonicalBody = structuredClone(body);
        if (req.method === 'POST' && req.path === '/api/orders') delete canonicalBody.orderNumber;
        const fingerprint = digest(JSON.stringify(canonicalBody));
        const receipts = getDb().collection('Api_Write_Receipts');
        const replay = async () => {
            const previous = receiptId && await receipts.findOne({ _id: receiptId });
            if (!previous) return false;
            if (previous.fingerprint !== fingerprint) {
                res.status(409).json({ error: 'This retry key belongs to a different request' });
            } else res.status(previous.status).json(previous.body);
            return true;
        };
        let session;
        try {
            if (await replay()) return;
            session = getClient().startSession();
            let response;
            await session.withTransaction(async () => {
                req.body = structuredClone(body);
                let status = 200;
                response = undefined;
                const capture = {
                    status(code) { status = code; return this; },
                    json(value) { response = { status, body: value }; return this; }
                };
                await writes.run({ session }, () => handler(req, capture));
                if (!response) throw failure('Write did not produce a response', 500);
                if (response.status >= 400) throw failure(response.body.error || response.body.message || 'Write failed', response.status);
                if (receiptId) await receipts.insertOne({ _id: receiptId, fingerprint, ...response,
                    createdAt: new Date() }, { session });
            });
            res.status(response.status).json(response.body);
        } catch (error) {
            if (error.code === 11000 && await replay()) return;
            res.status(error.status || 503).json({ error: error.message || 'Write could not be confirmed; retry the same request' });
        } finally {
            await session?.endSession();
        }
    };
}

async function issueSession(db, user) {
    const token = randomBytes(32).toString('hex');
    await db.collection('App_Sessions').insertOne({ _id: digest(token), userId: user._id,
        expiresAt: new Date(Date.now() + 7 * 86400000) });
    return token;
}

async function revokeSession(db, authorizationHeader) {
    const token = String(authorizationHeader || '').replace(/^Bearer\s+/i, '');
    if (token) await db.collection('App_Sessions').deleteOne({ _id: digest(token) });
}

function authorization(getDb, getCollections) {
    return async (req, res, next) => {
        const path = req.path;
        const protectedPath = /^\/(session$|orders(?:\/|$)|load-delivery(?:\/|$)|salesman-data\/|collection-history\/salesman\/|payments\/salesman\/|outstanding\/salesman(?:-legacy)?\/)/.test(path);
        if (!protectedPath) return next();
        try {
            const token = String(req.get('Authorization') || '').replace(/^Bearer\s+/i, '');
            const db = getDb();
            const collections = getCollections();
            const session = token && await db.collection('App_Sessions').findOne({ _id: digest(token), expiresAt: { $gt: new Date() } });
            const user = session && await collections.register.findOne({ _id: session.userId });
            if (!user || user.isActive === false) return res.status(401).json({ error: 'Please sign in again' });
            req.auth = user;
            const tenant = String(user.distributor_id || user.distributorId || '');
            const salesman = String(user.salesman_id || '');
            if (!tenant || !['salesman', 'distributor'].includes(user.role)) throw failure('Account has no distributor access', 403);
            const deny = () => { throw failure('You do not have access to this record', 403); };
            const segments = path.split('/').filter(Boolean).map(decodeURIComponent);
            const supplied = { ...req.query, ...req.body };
            for (const field of ['distributorId', 'distributor_id']) {
                if (supplied[field] && String(supplied[field]) !== tenant) deny();
            }
            if (user.role === 'salesman') {
                for (const field of ['salesmanId', 'salesman_id']) {
                    if (supplied[field] && String(supplied[field]) !== salesman) deny();
                }
                if (path.endsWith('/assign') || path.endsWith('/upload')) deny();
            }
            const salesmanPath = path.match(/\/(?:salesman|salesman-legacy|salesman-data)\/([^/]+)/);
            if (salesmanPath) {
                const id = decodeURIComponent(salesmanPath[1]);
                if (user.role === 'salesman' && id !== salesman) deny();
                if (user.role === 'distributor' && !await collections.register.findOne({ salesman_id: id, distributor_id: tenant })) deny();
            }
            if (segments[0] === 'orders') {
                if (user.role === 'salesman') {
                    const permission = req.method === 'GET' ? 'canViewOrders' :
                        req.method === 'DELETE' ? 'canDeleteOrder' :
                        path.endsWith('/payment') ? 'canCollectPayment' :
                        req.method === 'POST' ? 'canCreateOrder' : 'canEditOrder';
                    if (user.permissions?.[permission] === false) deny();
                }
                if (segments[1] === 'distributor' || segments[1] === 'download') {
                    if (segments[2] !== tenant) deny();
                    if (user.role === 'salesman') deny();
                } else if (segments[1] && !['salesman', 'customer'].includes(segments[1])) {
                    const id = segments[1] === 'status' ? segments[2] : segments[1];
                    const order = await collections.order.findOne(ObjectId.isValid(id) ?
                        { $or: [{ _id: new ObjectId(id) }, { orderNumber: id }] } : { orderNumber: id });
                    if (!order || String(order.distributor_id || order.distributorId) !== tenant ||
                        (user.role === 'salesman' && order.salesman_id !== salesman)) deny();
                }
                if (req.method === 'POST' && segments.length === 1) {
                    const customerId = supplied.customerId;
                    const identity = customerId && ObjectId.isValid(customerId) ?
                        { $or: [{ _id: new ObjectId(customerId) }, { customer_id: customerId }] } : { customer_id: customerId };
                    const customer = await collections.customer.findOne({ $and: [identity,
                        { $or: [{ distributor_id: tenant }, { distributorId: tenant }] }] });
                    if (!customer) deny();
                    req.body.distributor_id = tenant;
                    req.body.distributorId = tenant;
                    if (user.role === 'salesman') {
                        req.body.salesman_id = salesman;
                        req.body.salesmanName = user.fullName || salesman;
                        req.body.created_by_type = 'salesman';
                    }
                }
            }
            if (segments[0] === 'load-delivery' && segments[1] !== 'route' && segments[1] !== 'upload') {
                const loadId = segments[1] === 'delivery-status' ? req.body.loadDocumentId : segments.length > 2 ? segments[1] : null;
                if (loadId) {
                    if (!ObjectId.isValid(loadId)) deny();
                    const load = await db.collection('Mas_Delivery').findOne({ _id: new ObjectId(loadId), distributorId: tenant });
                    if (!load || (user.role === 'salesman' && load.assignedSalesmanId !== salesman)) deny();
                } else {
                    if (segments[1] !== tenant) deny();
                    if (user.role === 'salesman' && req.query.salesmanId !== salesman) deny();
                }
            }
            next();
        } catch (error) { res.status(error.status || 500).json({ error: error.message }); }
    };
}

module.exports = { transactionalCollection, reliableWrite, issueSession, revokeSession, authorization,
    paymentBalance, adjustStock, stockQuantity, readCoordinate, writes, failure };
