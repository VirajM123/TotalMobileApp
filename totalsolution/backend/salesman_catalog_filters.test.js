const test = require('node:test');
const assert = require('node:assert/strict');
const {
    buildSalesmanCustomerBrowseQuery,
    buildSalesmanProductBrowseQuery
} = require('./salesman_catalog_filters');

function getValue(document, path) {
    return path.split('.').reduce((value, key) => value == null ? undefined : value[key], document);
}

function matchesValue(value, condition) {
    if (condition instanceof RegExp) return condition.test(String(value ?? ''));
    if (condition instanceof Date) return new Date(value).getTime() >= condition.getTime();
    if (condition === null || typeof condition !== 'object' || Array.isArray(condition)) {
        return Array.isArray(value) ? value.includes(condition) : value === condition;
    }
    return Object.entries(condition).every(([operator, expected]) => {
        if (operator === '$exists') return (value !== undefined) === expected;
        if (operator === '$in') {
            return expected.some(item => item === null
                ? value == null
                : Array.isArray(value) ? value.includes(item) : value === item);
        }
        if (operator === '$ne') return value !== expected;
        if (operator === '$not') return !matchesValue(value, expected);
        if (operator === '$gte') {
            return expected instanceof Date
                ? new Date(value).getTime() >= expected.getTime()
                : value >= expected;
        }
        if (operator === '$gt') return value > expected;
        if (operator === '$lte') return value <= expected;
        if (operator === '$lt') return value < expected;
        return false;
    });
}

function matches(document, query) {
    return Object.entries(query).every(([key, condition]) => {
        if (key === '$and') return condition.every(part => matches(document, part));
        if (key === '$or') return condition.some(part => matches(document, part));
        return matchesValue(getValue(document, key), condition);
    });
}

function fetchPage(documents, query, { page = 1, limit = 200, sortField }) {
    const filtered = documents
        .filter(document => matches(document, query))
        .sort((left, right) =>
            String(left[sortField] ?? '').localeCompare(String(right[sortField] ?? '')) ||
            String(left._id).localeCompare(String(right._id)));
    const rows = filtered.slice((page - 1) * limit, page * limit + 1);
    return {
        rows: rows.slice(0, limit),
        total: filtered.length,
        hasMore: rows.length > limit
    };
}

test('search and status filters find customer matches beyond page one', () => {
    const customers = Array.from({ length: 450 }, (_, index) => ({
        _id: `c${String(index).padStart(3, '0')}`,
        name: `Customer ${String(index).padStart(3, '0')}`,
        status: index === 421 ? 'active' : 'inactive',
        customer_id: index === 421 ? 'MATCH-421' : `CODE-${index}`,
        distributor_id: 'd1'
    }));
    const query = buildSalesmanCustomerBrowseQuery({
        distributorId: 'd1',
        search: 'match-421',
        status: 'active'
    });
    const page = fetchPage(customers, query, { page: 1, sortField: 'name' });

    assert.deepEqual(page.rows.map(row => row._id), ['c421']);
    assert.equal(page.total, 1);
    assert.equal(page.hasMore, false);
});

test('customer filtering and company/route restrictions happen before pagination', () => {
    const customers = Array.from({ length: 430 }, (_, index) => ({
        _id: `c${String(index).padStart(3, '0')}`,
        name: `Customer ${String(index).padStart(3, '0')}`,
        status: index < 205 ? 'inactive' : 'active',
        distributor_id: 'd1',
        sysCompCode: index === 420 ? 'company-a' : 'company-b',
        route: index === 420 ? 'route-a' : 'route-b'
    }));
    customers[420].name = 'Needle Shop';

    const query = buildSalesmanCustomerBrowseQuery({
        distributorId: 'd1',
        company: 'company-a',
        route: 'route-a',
        search: 'needle',
        status: 'active'
    });
    const page = fetchPage(customers, query, { limit: 1, sortField: 'name' });

    assert.deepEqual(page.rows.map(row => row._id), ['c420']);
    assert.equal(page.total, 1);
    assert.equal(page.hasMore, false);
});

test('inactive routes can match the associated area without crossing routes', () => {
    const query = buildSalesmanCustomerBrowseQuery({
        distributorId: 'd1',
        route: 'route-a',
        status: 'inactive'
    });
    const customers = [
        { _id: '1', distributor_id: 'd1', status: 'inactive', route: '', area: 'route-a' },
        { _id: '2', distributor_id: 'd1', status: 'inactive', route: 'route-b', area: 'route-a' },
        { _id: '3', distributor_id: 'd2', status: 'inactive', route: 'route-a' }
    ];

    assert.deepEqual(fetchPage(customers, query, { sortField: 'name' }).rows.map(row => row._id), ['1']);
});

test('new-customer filter uses one stable cutoff across its pages', () => {
    const cutoff = '2026-10-01T12:00:00.000Z';
    const query = buildSalesmanCustomerBrowseQuery({
        distributorId: 'd1',
        status: 'new',
        createdAfter: cutoff
    });
    const customers = Array.from({ length: 205 }, (_, index) => ({
        _id: `c${String(index).padStart(3, '0')}`,
        name: `Customer ${String(index).padStart(3, '0')}`,
        distributor_id: 'd1',
        created_at: new Date(Date.parse(cutoff) + index * 1000).toISOString()
    }));
    customers[0].created_at = '2026-10-01T11:59:59.999Z';

    const first = fetchPage(customers, query, { limit: 100, sortField: 'name' });
    const second = fetchPage(customers, query, { page: 2, limit: 100, sortField: 'name' });
    const last = fetchPage(customers, query, { page: 3, limit: 100, sortField: 'name' });

    assert.equal(first.total, 204);
    assert.equal(second.total, first.total);
    assert.equal(last.total, first.total);
    assert.equal(first.rows.length + second.rows.length + last.rows.length, 204);
    assert.equal(new Set([...first.rows, ...second.rows, ...last.rows].map(row => row._id)).size, 204);
});

test('product search and stock ranges combine before page metadata is calculated', () => {
    const products = Array.from({ length: 450 }, (_, index) => ({
        _id: `p${String(index).padStart(3, '0')}`,
        productName: `Product ${String(index).padStart(3, '0')}`,
        sku: index >= 205 && index < 410 ? `MATCH-${index}` : `SKU-${index}`,
        stock: index >= 205 && index < 410 ? 4 : 20,
        isActive: true,
        distributorId: 'd1'
    }));
    const query = buildSalesmanProductBrowseQuery({
        distributorId: 'd1',
        search: 'match',
        stock: 'low'
    });
    const first = fetchPage(products, query, { page: 1, limit: 100, sortField: 'productName' });
    const second = fetchPage(products, query, { page: 2, limit: 100, sortField: 'productName' });
    const allIds = [...first.rows, ...second.rows].map(row => row._id);

    assert.equal(first.total, 205);
    assert.equal(first.hasMore, true);
    assert.equal(second.total, 205);
    assert.equal(second.hasMore, true);
    assert.equal(new Set(allIds).size, allIds.length);
    assert.equal(allIds.length, 200);
    assert.deepEqual(fetchPage(products, query, {
        page: 3,
        limit: 100,
        sortField: 'productName'
    }).rows.map(row => row._id), ['p405', 'p406', 'p407', 'p408', 'p409']);
});

test('product stock fallback and company association are retained', () => {
    const query = buildSalesmanProductBrowseQuery({
        distributorId: 'd1',
        company: 'company-a',
        stock: 'out'
    });
    const products = [
        { _id: '1', distributorId: 'd1', isActive: true, companyCode: 'company-a' },
        { _id: '2', distributorId: 'd1', isActive: true, companyCode: 'company-b', stock: 0 },
        { _id: '3', distributorId: 'd1', isActive: true, sysCompCode: 'company-a', stockQuantity: 0 },
        { _id: '4', distributorId: 'd2', isActive: true, sysCompCode: 'company-a', stock: 0 }
    ];

    assert.deepEqual(fetchPage(products, query, { sortField: 'productName' }).rows.map(row => row._id), ['1', '3']);
});

test('default query builders preserve legacy unfiltered catalog scope', () => {
    assert.deepEqual(
        buildSalesmanCustomerBrowseQuery({ distributorId: 'd1' }),
        { distributor_id: 'd1' }
    );
    assert.deepEqual(
        buildSalesmanProductBrowseQuery({ distributorId: 'd1' }),
        { distributorId: 'd1', isActive: true }
    );
});
