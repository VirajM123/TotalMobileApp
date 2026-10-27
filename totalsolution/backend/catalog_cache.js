const { BSON } = require('mongodb');

// Single-flight reads with bounded retained data. Invalidated reads may finish
// for their original caller, but cannot repopulate the cache after a write.
class CatalogCache {
    constructor({ ttlMs = 5000, maxEntries = 50, maxBytes = 32 * 1024 * 1024, now = Date.now } = {}) {
        this.ttlMs = Number.isFinite(ttlMs) ? Math.max(0, ttlMs) : 5000;
        this.maxEntries = maxEntries;
        this.maxBytes = maxBytes;
        this.now = now;
        this.entries = new Map();
        this.inFlight = new Map();
        this.bytes = 0;
        this.generation = 0;
        this.activeWrites = 0;
    }

    remove(key) {
        const entry = this.entries.get(key);
        if (entry) this.bytes -= entry.bytes;
        this.entries.delete(key);
    }

    clear() {
        this.generation++;
        this.entries.clear();
        this.inFlight.clear();
        this.bytes = 0;
    }

    beginWrite() {
        this.activeWrites++;
        this.clear();
        let ended = false;
        return () => {
            if (ended) return;
            ended = true;
            this.activeWrites--;
            this.clear();
        };
    }

    get(key, fetchRows) {
        for (const [entryKey, entry] of this.entries) {
            if (entry.expires <= this.now()) this.remove(entryKey);
        }
        if (this.activeWrites) return Promise.resolve().then(fetchRows);
        const hit = this.entries.get(key);
        if (hit) {
            this.entries.delete(key);
            this.entries.set(key, hit);
            return Promise.resolve(hit.rows);
        }
        if (this.inFlight.has(key)) return this.inFlight.get(key);
        const generation = this.generation;
        const promise = Promise.resolve().then(fetchRows).then(rows => {
            if (this.ttlMs > 0 && generation === this.generation && !this.activeWrites) {
                // Cache bookkeeping must never turn a successful DB read into
                // an API failure for an unusual value returned by a provider.
                let bytes;
                try { bytes = BSON.calculateObjectSize({ rows }); }
                catch { return rows; }
                if (bytes <= this.maxBytes && this.maxEntries > 0) {
                    while (this.entries.size >= this.maxEntries || this.bytes + bytes > this.maxBytes) {
                        this.remove(this.entries.keys().next().value);
                    }
                    this.entries.set(key, { rows, bytes, expires: this.now() + this.ttlMs });
                    this.bytes += bytes;
                }
            }
            return rows;
        }).finally(() => {
            if (this.inFlight.get(key) === promise) this.inFlight.delete(key);
        });
        this.inFlight.set(key, promise);
        return promise;
    }
}

module.exports = { CatalogCache };
