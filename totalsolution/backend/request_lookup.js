// Instantiate inside a request only: reuse repeated lookups during an export
// without retaining customer/product data across requests or tenants.
function requestLookup() {
    const pending = new Map();
    return (key, load) => {
        if (!pending.has(key)) {
            const promise = Promise.resolve().then(load).catch(error => {
                pending.delete(key);
                throw error;
            });
            pending.set(key, promise);
        }
        return pending.get(key);
    };
}

module.exports = { requestLookup };
