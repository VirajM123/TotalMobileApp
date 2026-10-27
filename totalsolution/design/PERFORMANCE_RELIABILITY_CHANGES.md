# Performance and reliability changes

## Implemented

- Backend begins listening only after MongoDB connection and index creation.
  Requests cannot enter handlers with uninitialized collections during startup.
- Catalog cache retains at most 50 entries and 32 MiB of BSON-encoded data per
  backend process. This is a data budget, not a cap on JavaScript heap memory.
  Oversized results are returned in full without retention. Expired entries are
  removed on access, and least recently used entries are evicted under pressure.
- Concurrent identical catalog queries share one in-flight read. Failed queries
  are not retained. Catalog/customer/product/import/order mutations invalidate
  the cache before and after the request and bypass it during writes. Old reads
  cannot refill the cache after invalidation. Invalidation is conservative across
  tenants to support legacy requests without trusted tenant context.
- Customer/salesman deletion guards use a projected single-record existence
  lookup instead of loading every matching order. Their rejection rules remain.
- Excel order exports reuse product, salesman and registration lookups within
  each request. Repeated rows retain the same output fields/order/calculations;
  lookup failures can be retried and values are not cached across requests.
- Added compound indexes for notification counts/lists and stable order-list
  sorting. Existing indexes remain. Indexes are created on backend startup;
  existing large databases may take longer on the first restart.
- Notification polling keeps its five-second foreground interval, prevents
  overlapping count requests, pauses in the background, resumes with a refresh,
  and ignores old count responses after account changes/disposal. Repeated
  mark-read operations cannot decrement the local count twice or below zero.
- API URL can be configured at build/run time. The existing localhost default
  remains for compatibility. Example (substitute your actual backend URL):

  ```powershell
  flutter run --dart-define=API_BASE_URL=https://your-backend.example/api
  ```

  Use the `/api` suffix without a trailing slash. On a physical phone, localhost
  requires port forwarding; otherwise provide the reachable backend URL.
- Replaced the obsolete counter-demo smoke test with the real signed-out login
  screen test. Added cache-race, cache-budget, export lookup and notification
  lifecycle tests. No additional runtime dependencies were added.

## Verification

- Backend syntax check: `node --check server.js`.
- Backend suite: `npm test` (23 tests).
- Flutter suite: `flutter test --no-pub` (18 tests).
- Dart analysis of the changed screen/tests: no errors; existing screen warnings
  and informational lints remain.

These checks use controlled repositories and transports. They do not write live
business records or establish a measured device/API speed improvement.

## Remaining staging verification

Exercise login, catalog filtering, order create/edit/delete, payment retry,
stock rejection, export downloads, notification background/resume and delivery
completion on representative devices. Compare request count, response sizes,
API p95 latency and scroll frame times using realistic data and weak networks.

The existing full-history API modes remain for client compatibility. A complete
pagination migration needs corresponding screens/exports to consume every page;
silently truncating these modes would change functionality. Customer/product and
other legacy API authorization still needs a separate client-compatible security
pass. This change is not a full security audit or production load test.

Catalog invalidation is local to each backend process. Other instances rely on
the short TTL. Multi-instance immediate coherence requires shared invalidation
or disabling retained catalog data with `CATALOG_CACHE_TTL_MS=0`. Multi-instance
uploads also require shared file storage. Deployment and live field validation
have not been performed by this change.
