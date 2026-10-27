# Salesman reliability fixes

Implemented in the active login-screen app and its order, payment and load APIs.
Existing company/route selection, catalog paging, order payload fields, payment
modes, delivery radius and route chunking remain in place.

## Changes

- Login issues an expiring database-backed session. The active app sends it on
  JSON and multipart requests, checks it on restore and revokes it on logout.
  Protected order/load/salesman routes check the authenticated tenant, salesman
  and applicable order permissions. Completion also checks assignment in the
  database update.
- Order and order-payment POSTs use persistent retry keys. Server receipts are
  committed with their business writes, so a repeated request returns its original
  result. Changing a request while reusing a key returns a conflict. Uncertain
  keys survive app restarts and logout; successful requests retire their keys.
- Order creation, editing, deletion and order-payment recording use MongoDB
  transactions. Related stock, collection history and notifications participate
  in the same transaction. Failure does not produce a success response.
- Paid/due balances are calculated consistently. Payment amounts must be positive
  and cannot exceed the remaining order total.
- Stock changes are tenant-scoped atomic increments. Insufficient stock rejects
  the write. The existing quantity/freeQty stock convention is retained.
- A load can open without GPS. Navigation and completion still require a usable
  location. A valid location has accuracy within 100 metres and is at most 60
  seconds old, allowing five seconds of future clock skew.
- Missing outlet pins have a completion exception with a required reason of
  10–500 characters. The server records the actor, reason, GPS and timestamps.
  Valid outlet pins retain the 150-metre proximity rule. Coordinate aliases and
  blank values are interpreted consistently with the app.
- Completion retries preserve the first completed result. Repeated completion
  taps are guarded locally. Tracking stops on completion, reassignment and logout.
- Route responses check the active load and request generation. Movement-based
  refreshes require 250 metres of movement and at least 60 seconds between
  attempts. Manual refresh and delivery-triggered refresh remain available.
  Google road-route requests have a 15-second server timeout.

## Verification

- Backend syntax checks passed.
- Backend tests: 15 passed, covering existing catalog filters plus coordinates, balance,
  stock, session, tenant, retry replay and transaction-wrapper failure behavior.
- Flutter tests: the final targeted run passed all 14 tests, including all catalog
  pager tests and four new HTTP session/retry tests. The existing counter-demo smoke test
  fails because it expects a counter in the login application. It was left
  unchanged.
- Static analysis found no compile errors in the changed Dart code. The large
  existing login screen still reports warnings and informational lints.
- A read-only MongoDB hello check confirmed that the configured deployment
  supports sessions and transactions. No production business records were
  created or changed for testing.

## Rollout and remaining verification

Deploy the backend and updated app together. Cached logins without a session
must sign in once. Sessions expire after seven days.

Other clients calling the protected shared APIs must also sign in through
`POST /api/login` and send its `token` as `Authorization: Bearer <token>`.
Salesman order/payment POSTs also require `Idempotency-Key`. Anonymous access
cannot be retained on these APIs while fixing their authorization vulnerability.

The configured database supports transactions; any different deployment must
also use a replica set or supported sharded cluster. Transaction failures fail
the write rather than falling back to a partially saved order or payment.

The backend tests use controlled repositories, not live business writes. Device
GPS behavior, Android/iOS lifecycle behavior, concurrent writes against a staging
database, and the complete distributor/desktop integration still need field or
staging verification. Existing historical stock/balance inconsistencies are not
rewritten by these code fixes. This is not a security audit of every legacy API.
