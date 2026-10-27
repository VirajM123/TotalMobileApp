const test = require('node:test');
const assert = require('node:assert/strict');
const { requestLookup } = require('./request_lookup');

test('repeated export rows share lookups; requests and identity types stay isolated', async () => {
    const lookup = requestLookup();
    let reads = 0;
    const load = async () => { reads++; return { mrp: 15 }; };
    const rows = await Promise.all(Array.from({ length: 1000 }, () => lookup('product:id:A', load)));
    assert.equal(reads, 1);
    assert.equal(rows.length, 1000);
    assert.ok(rows.every(row => row.mrp === 15));
    await lookup('product:sku:A', load);
    await requestLookup()('product:id:A', load);
    assert.equal(reads, 3);
});

test('missing records are reusable while failed lookups can be retried', async () => {
    const lookup = requestLookup();
    let calls = 0;
    await lookup('missing', async () => { calls++; return null; });
    assert.equal(await lookup('missing', async () => { calls++; return 1; }), null);
    assert.equal(calls, 1);
    await assert.rejects(lookup('failure', async () => { throw Error('offline'); }));
    assert.equal(await lookup('failure', async () => 42), 42);
});
