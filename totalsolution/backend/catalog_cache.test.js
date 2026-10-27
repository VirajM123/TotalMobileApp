const test = require('node:test');
const assert = require('node:assert/strict');
const { CatalogCache } = require('./catalog_cache');

function deferred() {
    let resolve;
    const promise = new Promise(done => { resolve = done; });
    return { promise, resolve };
}

test('concurrent catalog reads share a query; expiry reloads without changing rows', async () => {
    let now = 0, calls = 0;
    const cache = new CatalogCache({ now: () => now, ttlMs: 10 });
    const rows = [{ sku: 'B' }, { sku: 'A' }, { sku: 'A' }];
    const fetch = async () => { calls++; return rows; };
    const [a, b] = await Promise.all([cache.get('D1', fetch), cache.get('D1', fetch)]);
    assert.equal(calls, 1);
    assert.deepEqual(a, rows);
    assert.equal(a, b);
    await cache.get('D1', fetch);
    assert.equal(calls, 1);
    now = 11;
    await cache.get('D1', fetch);
    assert.equal(calls, 2);
});

test('failed queries are not retained and tenants do not share entries', async () => {
    const cache = new CatalogCache();
    await assert.rejects(cache.get('D1', async () => { throw Error('offline'); }));
    assert.deepEqual(await cache.get('D1', async () => [1]), [1]);
    assert.deepEqual(await cache.get('D2', async () => [2]), [2]);
});

test('writes prevent late reads from repopulating stale catalog data', async () => {
    const cache = new CatalogCache();
    const old = deferred();
    const pending = cache.get('D1', () => old.promise);
    const end = cache.beginWrite();
    assert.deepEqual(await cache.get('D1', async () => ['during']), ['during']);
    assert.equal(cache.entries.size, 0);
    end();
    end(); // Response finish and res.end may both fire.
    assert.equal(cache.activeWrites, 0);
    const current = deferred();
    const fresh = cache.get('D1', () => current.promise);
    old.resolve(['old']);
    await pending;
    assert.equal(cache.entries.size, 0);
    assert.equal(cache.inFlight.get('D1'), fresh);
    current.resolve(['new']);
    await fresh;
    assert.deepEqual(await cache.get('D1', async () => ['unexpected']), ['new']);
});

test('overlapping writes keep cache bypassed until all finish', async () => {
    const cache = new CatalogCache();
    const first = cache.beginWrite(), second = cache.beginWrite();
    first();
    await cache.get('D1', async () => [1]);
    assert.equal(cache.entries.size, 0);
    second();
    await cache.get('D1', async () => [2]);
    assert.equal(cache.entries.size, 1);
});

test('entry and byte budgets evict old data; oversized catalogs still return completely', async () => {
    const cache = new CatalogCache({ maxEntries: 2, maxBytes: 150 });
    const rows = [{ name: 'a'.repeat(40) }];
    for (const key of ['A', 'B', 'C']) await cache.get(key, async () => rows);
    assert.ok(cache.entries.size <= 2);
    assert.ok(cache.bytes <= 150);
    assert.equal(cache.entries.has('A'), false);
    const large = [{ name: 'b'.repeat(1000) }];
    assert.deepEqual(await cache.get('large', async () => large), large);
    assert.equal(cache.entries.has('large'), false);
});

test('zero TTL disables retention while preserving single-flight reads', async () => {
    const cache = new CatalogCache({ ttlMs: 0 });
    let calls = 0;
    const fetch = async () => { calls++; return []; };
    await Promise.all([cache.get('A', fetch), cache.get('A', fetch)]);
    assert.equal(calls, 1);
    await cache.get('A', fetch);
    assert.equal(calls, 2);
    assert.equal(cache.entries.size, 0);
});
