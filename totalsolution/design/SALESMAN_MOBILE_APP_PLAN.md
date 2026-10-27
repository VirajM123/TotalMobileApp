# Salesman Mobile App Plan

**Purpose:** Plan improvements to the salesman’s mobile delivery and ordering experience, including resilience and high-traffic readiness.

**Scope:** Planning only. This document covers the salesman-facing app and the API/order reliability it depends on. The admin live-tracking screen and location-history policy are covered separately in [`SALESMAN_LOAD_TRACKER_PLAN.md`](./SALESMAN_LOAD_TRACKER_PLAN.md).

## Current state

- The active salesman flow is mainly in [`lib/screens/auth/login_screen.dart`](../lib/screens/auth/login_screen.dart).
- The app requests assigned load deliveries using a salesman ID, obtains GPS when a load starts, displays a Google map with outlet markers and a route line, and receives periodic GPS position updates while the delivery is active.
- The backend can create route plans and request Google traffic-aware road routes. Coordinate-distance ordering is available as a fallback, and the route endpoint currently limits a request to 25 stops.
- The app filters invalid/missing outlet coordinates out of route/map stops. This can make a load look incomplete if an outlet’s latitude/longitude is absent or stored under an unsupported field name.
- The app currently has a short-lived backend cache for salesman catalog reads, but this is an in-process cache and does not provide shared cache consistency across server instances.
- Order creation is synchronous through the backend. The order endpoint inserts an order, updates stock, and creates a notification asynchronously. The current backend catches/logs stock update failures, so order acceptance alone does not guarantee every side effect succeeded.
- Mobile and server both perform delivery proximity checks. Any exception workflow must be consistent and auditable rather than silently bypassing these checks.

## Salesman home and load entry

Create a clear **Today / My Work** landing view that prioritizes what the salesman is expected to do:

- Show assigned loads as cards with load number, route/company, outlet count, delivered/pending totals, and last refresh time.
- Offer one primary action per load: **Start delivery** or **Resume**.
- Refresh assigned loads on opening, with visible manual refresh and understandable loading/error/offline states.
- Distinguish “no load assigned,” “load has no outlets,” “outlet locations need correction,” and “could not connect.”
- Do not require the salesman to understand internal load series or hidden filter steps.
- Keep order creation, customer lookup, and other permitted work accessible without crowding the delivery task.

## Active delivery map and stop workflow

### Map

- Use the existing Google Maps foundation to provide a large, clear map or a map/list switch.
- Show the salesman’s vehicle marker at the latest valid position; rotate it only when heading is reliable.
- Show numbered outlet markers, completion state, highlighted next outlet, and planned route polyline.
- Provide recenter/follow controls, distance/ETA, and a visible last-location-update time.
- Animate between accepted positions but reject inaccurate jumps and allow the user to pan without forced camera-follow.
- Label route quality: road-time, coordinate-distance, or manual/fallback.

### Stop details and delivery actions

- Show the next outlet’s name, address, distance, and a **Navigate** action.
- Make **Delivered** and **Could not deliver** clear, large actions with confirmation as appropriate.
- Preserve the full outlet list even when coordinates are invalid; label those outlets **Location needed** and offer a practical next step.
- Record delivery status idempotently and show whether it is saved, pending sync, or confirmed by the server.
- Provide a reasoned, auditable exception workflow for missing outlet pins, GPS inaccuracy, or other legitimate edge cases. Keep app and server validation consistent.

### Route and map fallback

- Do not block starting or working a load because the route provider, GPS, or map is unavailable.
- If permission is denied or GPS is disabled, explain the issue and provide the allowed list-based workflow.
- If data is unavailable, preserve the current load and show when it was last refreshed.
- Handle more than 25 stops using bounded route chunks/provider-supported waypoint strategies; never silently drop remaining stops.
- Keep delivery completion and payment actions available where policy allows, even if route guidance fails.

## Location use in the mobile app

Location sharing should be visible, limited, and respectful:

- Explain location use when the salesman starts an assigned delivery and show an active-sharing indicator.
- Begin sharing only for an active assigned load, and stop on completion, cancellation, reassignment, or logout.
- Use foreground tracking first. If background tracking is required, separately design platform permissions, persistent indicators/notifications, and battery tests.
- Validate accuracy and sample age before moving the vehicle marker or using a GPS sample for proximity checks.
- Keep live position transport separate from Google Routes calls. Recalculate route/ETA on meaningful events (load start, stop completion/skip, material deviation, or a throttled interval), not for every GPS sample.
- Throttle location samples based on movement and elapsed time. Tune with field testing; a starting experiment could be every 5–15 seconds while moving and less frequently while stationary.
- During network loss, keep only a bounded local buffer. Send the latest valid position first on reconnect and label older samples as historical, not live.

## Order creation and write reliability

The app must avoid losing or duplicating orders when users retry after a timeout or lose connectivity.

- Generate a stable idempotency key for each order attempt and persist it until the server confirms the result.
- On the server, enforce idempotency so a repeated request returns the original order result rather than creating a duplicate.
- Show distinct **Sending**, **Confirmed**, **Pending**, and **Failed** states. Do not report “order placed” until durable acceptance is confirmed.
- If offline order drafting is supported, store it securely on-device, clearly label it unsent, and retry with the same idempotency key.
- Validate order data before submit and prevent accidental repeat taps while a request is in flight.
- Make stock updates and notifications observable, retryable side effects. Use a durable queue/outbox for non-critical work so the order and its follow-up events do not silently drift.
- Define stock consistency explicitly. Do not treat a successful order response as proof that stock was adjusted unless the system guarantees that behavior.

## Speed and scale for the mobile app

These are separate remedies for separate bottlenecks; use metrics to determine when each is needed.

| Need | Mobile-app/backend plan | Guardrail |
|---|---|---|
| Slow/repeated reads: cache | Cache stable catalogs/reference data; use bounded TTL, pagination, projections, and explicit invalidation. Use shared cache if API runs on multiple instances. | Do not use stale data as authority for order stock, permissions, balances, assignments, or delivery completion. |
| Slow writes: queue | Keep critical order acceptance durable and idempotent. Queue retries and non-critical notifications, analytics, exports, and sync work. Provide pending/confirmed/failed states. | A queue must not turn a failed or unpersisted order into a success-looking response. |
| Too much API traffic: load balancer | Use stateless, health-checked API instances behind a load balancer, with autoscaling, timeouts, backpressure, rate limits, and graceful degradation. | A load balancer does not remove a database or third-party API bottleneck. Move uploaded files off instance-local disk. |
| Database read pressure: read replicas | Add indexes based on query plans; send stale-safe history/catalog reads to replicas where appropriate. | Use primary/consistent reads for writes and read-after-write validation. Account for replication lag. |
| Location traffic | Throttle on device and server; separate latest position from short-retention history; avoid routing calls per ping. | Do not append every position to a large load document or overwhelm the map provider. |

### What “100,000 at the same time” means

Agree on a measurable target before deciding infrastructure capacity:

- 100,000 registered salesmen versus 100,000 concurrent sessions.
- 100,000 online users versus 100,000 order submissions per second/minute.
- Location pings per active delivery versus order/catalog/admin traffic.
- Normal load versus retry bursts after network recovery.

Run staged load, soak, and recovery tests on production-like infrastructure. Measure durable order success, duplicate rate, p50/p95/p99 latency, timeout/error rate, queue lag, MongoDB CPU/connections/replication lag, cache hit rate, location freshness, map-provider quota/cost, and recovery time. Capacity must be demonstrated by tests against agreed targets; it cannot be guaranteed by adding named components alone.

## Mobile experience and reliability roadmap

### Phase 1 — Fix assigned load and outlet visibility

- Trace a real missing-outlet case from admin upload/assignment to API response and app filtering.
- Normalize coordinate aliases, report invalid coordinates, retain all outlets in the list, and test route waypoint limits.
- **Accept when:** every assigned outlet appears in the app; valid pins are mappable; invalid pins are clearly marked; map/routing failure does not block delivery work.

### Phase 2 — Improve delivery workflow

- Add Today/Assigned Loads, clear start/resume states, stop list/map, next-stop card, navigation, delivery result, and exception flow.
- Test permission denial, location accuracy, weak GPS, offline operation, app resume, and route-provider timeout.
- **Accept when:** a salesman can start, pause/resume, complete, or report an exception without losing progress or duplicating a result.

### Phase 3 — Make ordering resilient

- Add idempotency, durable order state, retry-safe side effects, and clear order-status states.
- Add secure offline drafting only if business requirements approve the data and conflict model.
- **Accept when:** a timeout/retry does not create duplicate orders, and the app never displays a failed/unpersisted order as confirmed.

### Phase 4 — Validate scale

- Instrument API and database latency, catalog reads, order writes, location pings, and external route calls.
- Add shared cache, queue/outbox, load-balanced API instances, or read replicas only for measured bottlenecks.
- Load test to the agreed 100k-user/order-rate profile, including reconnect bursts and dependency failures.
- **Accept when:** service-level targets are met and order correctness is preserved during retries and recovery.

## Decisions required before implementation

1. Should location sharing be limited to an active assigned delivery?
2. Does the app need background tracking when it is not visible?
3. Is offline order drafting required, or only retrying already-submitted requests?
4. Does “100,000 at the same time” mean concurrent users or a defined order rate?
5. What devices/network conditions should field testing cover?

## Related project references

- Active salesman flow and location/map code: [`lib/screens/auth/login_screen.dart`](../lib/screens/auth/login_screen.dart)
- Order creation and load-delivery APIs: [`backend/server.js`](../backend/server.js)
- Google Maps/geolocation packages: [`pubspec.yaml`](../pubspec.yaml)
- Admin tracker-specific plan: [`SALESMAN_LOAD_TRACKER_PLAN.md`](./SALESMAN_LOAD_TRACKER_PLAN.md)
