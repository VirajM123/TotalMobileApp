const test = require('node:test');
const assert = require('node:assert/strict');
const { ObjectId } = require('mongodb');
const { paymentBalance, stockQuantity, adjustStock, transactionalCollection,
    reliableWrite, authorization, issueSession, readCoordinate, writes } = require('./salesman_reliability');

test('blank coordinate aliases do not become a false zero-degree outlet pin', () => {
    assert.equal(readCoordinate({ GeoLatitude: '', latitude: '12,5' }, ['GeoLatitude', 'latitude']), 12.5);
    assert.equal(Number.isNaN(readCoordinate({ GeoLatitude: 'null' }, ['GeoLatitude'])), true);
    assert.equal(readCoordinate({ latitude: 0 }, ['latitude']), 0);
});

test('paid and partial orders retain only the remaining balance', () => {
    assert.deepEqual(paymentBalance(1000, 1000), { paidAmount: 1000, dueAmount: 0, payment_status: 'paid' });
    assert.equal(paymentBalance(1000, 250).dueAmount, 750);
    assert.equal(paymentBalance(1000, 0).payment_status, 'pending');
    for (const paid of [-1, 1001, NaN, Infinity]) assert.throws(() => paymentBalance(1000, paid));
});

test('stock adjustment is tenant-scoped and conditional on available units', async () => {
    const calls = [];
    const products = { async updateOne(filter, update) { calls.push({ filter, update }); return { matchedCount: 1 }; } };
    await adjustStock(products, [{ sku: 'A', quantity: 4 }], 'D1');
    assert.deepEqual(calls[0].filter.stock, { $gte: 4 });
    assert.deepEqual(calls[0].filter.$or, [{ distributorId: 'D1' }, { distributor_id: 'D1' }]);
    assert.equal(calls[0].update.$inc.stock, -4);
    await adjustStock(products, [{ sku: 'A', quantity: 4 }], 'D1', true);
    assert.equal(calls[1].update.$inc.stock, 4);
    assert.equal(calls[1].filter.stock, undefined);
    await assert.rejects(adjustStock({ async updateOne() { return { matchedCount: 0 }; } }, [{ sku: 'A', quantity: 4 }], 'D1'), /insufficient stock/);
    assert.throws(() => stockQuantity({ quantity: -1 }));
    assert.throws(() => stockQuantity({ quantity: 1.5 }));
});

test('collection helpers use the request transaction session without leaking it', async () => {
    const seen = [];
    const collection = transactionalCollection({ async insertOne(doc, options) { seen.push(options); } });
    const session = {};
    await writes.run({ session }, () => collection.insertOne({}));
    await collection.insertOne({});
    assert.equal(seen[0].session, session);
    assert.equal(seen[1], undefined);
});

function fixture() {
    let receipts = new Map();
    let count = 0;
    const db = { collection() { return {
        async findOne(query) { return receipts.get(query._id); },
        async insertOne(doc) { receipts.set(doc._id, structuredClone(doc)); }
    }; } };
    const client = { startSession() { return {
        async withTransaction(callback) {
            const saved = new Map(receipts);
            const oldCount = count;
            try { await callback(); } catch (error) { receipts = saved; count = oldCount; throw error; }
        }, async endSession() {}
    }; } };
    const request = (body, key = 'stable-key') => ({ method: 'POST', path: '/api/orders', originalUrl: '/api/orders',
        auth: { _id: 'U1', role: 'salesman' }, body, get() { return key; } });
    const response = () => ({ code: 200, status(code) { this.code = code; return this; }, json(body) { this.body = body; return this; } });
    return { db, client, request, response, increment() { count++; }, count() { return count; } };
}

test('a lost order response can be replayed without another write', async () => {
    const f = fixture();
    const handler = reliableWrite(() => f.client, () => f.db, async (req, res) => {
        f.increment(); res.json({ success: true, orderNumber: 'ORD1' });
    });
    const first = f.response(), second = f.response();
    await handler(f.request({ orderNumber: 'client1', items: [1] }), first);
    await handler(f.request({ orderNumber: 'client2', items: [1] }), second);
    assert.equal(f.count(), 1);
    assert.deepEqual(second.body, first.body);
    const conflict = f.response();
    await handler(f.request({ items: [2] }), conflict);
    assert.equal(conflict.code, 409);
});

test('handler failures roll back writes and do not reserve the retry key', async () => {
    const f = fixture();
    let fail = true;
    const handler = reliableWrite(() => f.client, () => f.db, async (req, res) => {
        f.increment();
        if (fail) throw new Error('stock failed');
        res.json({ success: true });
    });
    const first = f.response();
    await handler(f.request({}), first);
    assert.equal(first.code, 503);
    assert.equal(f.count(), 0);
    fail = false;
    await handler(f.request({}), f.response());
    assert.equal(f.count(), 1);
});

test('salesman writes require a retry key', async () => {
    const f = fixture();
    const handler = reliableWrite(() => f.client, () => f.db, async () => assert.fail('must not write'));
    const res = f.response();
    await handler(f.request({}, ''), res);
    assert.equal(res.code, 400);
});

test('authentication rejects forged identity, expired sessions and reassigned loads', async () => {
    const userId = new ObjectId();
    let session, assignedSalesmanId = 'SM1';
    const user = { _id: userId, role: 'salesman', salesman_id: 'SM1', distributor_id: 'D1' };
    const db = { collection(name) { return { async findOne(query) {
        if (name === 'App_Sessions') return session && session.expiresAt > new Date() ? session : null;
        return { distributorId: 'D1', assignedSalesmanId };
    }, async insertOne(doc) { session = doc; } }; } };
    const auth = authorization(() => db, () => ({ register: { async findOne() { return user; } } }));
    const token = await issueSession(db, user);
    const run = async (path, query = {}, body = {}) => {
        let allowed = false;
        const res = { code: 200, status(code) { this.code = code; return this; }, json(body) { this.body = body; } };
        await auth({ path, method: 'GET', query, body, get() { return `Bearer ${token}`; } }, res, () => { allowed = true; });
        return { allowed, code: res.code };
    };
    assert.equal((await run('/salesman-data/SM1')).allowed, true);
    assert.equal((await run('/salesman-data/SM2')).code, 403);
    assert.equal((await run('/load-delivery/D1', { salesmanId: 'SM1' })).allowed, true);
    assert.equal((await run('/load-delivery/D2', { salesmanId: 'SM1' })).code, 403);
    assignedSalesmanId = 'SM2';
    assert.equal((await run(`/load-delivery/${new ObjectId()}/plan`)).code, 403);
    session.expiresAt = new Date(0);
    assert.equal((await run('/salesman-data/SM1')).code, 401);
});
