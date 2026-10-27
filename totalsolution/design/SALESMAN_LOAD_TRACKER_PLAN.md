# Admin Salesman Load Tracker Plan

**Purpose:** Plan a live load-tracking feature for the distributor/admin panel, connected to the salesman’s active delivery load.

**Scope:** Planning only. This document covers the admin tracker and the backend/location data it needs. It does not cover the mobile app’s broader order-entry or performance roadmap.

## Current state

- The backend supports load uploads, salesman assignment, route plans, delivery status, and reconciliation in [`backend/server.js`](../backend/server.js).
- The mobile app already reads assigned loads, creates route plans, displays outlet markers and a route polyline, and collects high-accuracy location while delivery is active in [`lib/screens/auth/login_screen.dart`](../lib/screens/auth/login_screen.dart).
- The mobile location stream currently updates the app and can trigger route recalculation. In the reviewed backend, there is no endpoint storing ongoing location pings or providing a live position stream for an admin panel.
- Delivery completion stores the position used for an individual delivery. That is not a continuous location trail and must not be presented as one.
- Google Maps and Google Routes support are already part of the project. Google Routes is called by the backend, which keeps its API key off the mobile client.

## Goal and scope

Give an authorized distributor/admin a trustworthy view of:

- Which loads are assigned, active, paused/stale, or completed.
- Where an assigned salesman was last reported and when that position was received.
- The planned route, outlet locations, next stop, and completed/pending stops.
- Delivery exceptions and the timeline of important load events.

The tracker should clearly distinguish live position, stale last-known position, and historical replay. It should not imply that GPS proves delivery or employee conduct.

## Admin tracker experience

### Load list

- Add a **Live Load Tracker** entry to the existing distributor/admin load workflow.
- List loads with statuses: unassigned, assigned, active, paused/stale, and completed.
- Filter by salesman, load, route, and date.
- Show load number, assigned salesman, outlet count, delivered/pending totals, and last location update.
- Provide clear empty, loading, offline, and error states.

### Map and details panel

- Show the latest vehicle position with a small vehicle icon; rotate only when heading data is reliable.
- Show the route polyline, outlet pins, next stop, completed stops, and exceptions with visually distinct markers.
- Selecting a salesman or outlet should focus the map and show relevant details.
- Show the salesman, active load, current status, last update time, GPS accuracy, next outlet, and delivered/pending totals.
- Show route ETA/distance as estimates and indicate when routing data is unavailable or stale.
- Provide refresh/reconnect and a way to contact the assigned salesman.

### Timeline and history

Record a time-stamped, auditable timeline for:

- Load started, paused, resumed, completed, cancelled, or reassigned.
- Location sharing started/stopped.
- Outlet arrival, delivered, skipped, or delivery exception.
- Actor and server-received timestamp for each event.

Provide limited replay only for an explicitly selected load and authorized admin. Configure a retention period and delete or aggregate expired location history.

## Location ingestion and data flow

1. The salesman starts an assigned delivery load and is clearly informed that location sharing is active.
2. The mobile app sends a compact position event while that load is active; it stops reporting when the load is completed, cancelled, reassigned, or the salesman logs out.
3. The backend authenticates the request and verifies the user, active load assignment, and distributor relationship. It validates coordinates, timestamps, accuracy, payload size, and sequence/idempotency value.
4. The backend updates a latest-position record and, if history is required, appends a separately indexed, short-retention history record.
5. The admin tracker reads the latest position through a throttled polling endpoint or a managed real-time channel. A map repaint must not cause a database query per frame.

### Event fields

Include only fields needed for operations:

- Authenticated salesman identity and active load ID.
- Latitude/longitude, reported accuracy, and optional heading/speed.
- Device capture time and server receive time.
- Monotonically increasing sequence number or idempotency key.

Derive tenant identity from the authenticated principal/assignment wherever possible rather than trusting client-supplied IDs.

### Latest position versus history

- Store latest position separately from location history; do not rewrite a large load document for every GPS sample.
- Use indexes and TTL/retention controls for history. Partition by time/tenant/load only when measured volume justifies it.
- Keep latest location as operational state. Delivery status remains a separate business event with its own validation.
- Delayed buffered samples must be marked historical, never displayed as live.

## Freshness and failure states

- Define a configurable freshness window. Show **Live** only for an update within that window.
- Otherwise show **Last seen at [time]**, with the last position visually differentiated from a current position.
- Display the reported accuracy and avoid false precision.
- Handle GPS permission denial, location services disabled, poor accuracy, no network, server failure, and stopped background operation without implying tracking is healthy.
- Do not move the marker on an invalid, out-of-order, duplicate, or implausible location sample; log a diagnosable reason without retaining unnecessary personal data.

## Outlet coordinates and map quality

The app and backend currently handle multiple legacy coordinate names, including `GeoLatitude`, `geoLatitude`, `latitude`, `GeoLongitude`, and `longitude`. Missing or invalid outlet coordinates can make assigned outlets disappear from a map or route.

- Normalize aliases at the backend boundary.
- Validate latitude in `[-90, 90]`, longitude in `[-180, 180]`, reject `(0,0)`, and flag non-numeric or out-of-range values.
- Keep outlets with invalid coordinates visible in load details and label them **Location needed**; do not silently omit them from all views.
- Provide an admin coordinate-quality report and authorized pin-correction/confirmation workflow.
- Do not silently geocode ambiguous addresses or substitute the salesman’s location for an outlet location.
- Ensure desktop load re-uploads preserve assignment and delivery progress, and test that corrected coordinates are not overwritten by stale imports.

## Security, privacy, and operations

- Require authentication and authorization on every ingest, tracker read, and real-time subscription.
- Enforce distributor/tenant scope server-side; one distributor must never access another distributor’s loads or positions.
- Use TLS, audit admin access to current and historical location, and protect map/route API keys with platform/API restrictions.
- Collect precise location only during the approved work period, provide clear notice and a visible sharing state, and restrict access by role.
- Define retention and deletion policy before storing location trails.
- Do not use GPS as the sole evidence for payroll, discipline, or delivery completion.
- Establish monitoring for ingest success, stale-position rate, invalid samples, API latency, database load, real-time fanout, and map-provider quota/cost.

## Scale approach

- Throttle position sampling on the mobile device by elapsed time and movement; tune against field freshness and battery tests. An initial test range could be every 5–15 seconds while moving, less often while stationary.
- Apply server-side validation and rate limits so a faulty client cannot flood location storage.
- Keep latest-position reads efficient and publish updates through a real-time fanout layer or throttled polling. Avoid one database read per visible marker per repaint.
- Scale Node.js API instances behind a health-checked load balancer when metrics justify it; use shared state for subscriptions and do not rely on process-local caches for live state.
- Consider database read replicas only for stale-safe history/analytics reads. Read-after-write and assignment validation need appropriate consistency.
- Consider partitioning/sharding only after load tests identify database limits and query patterns are understood.
- Measure active tracked salesmen, location-event rate, burst/retry behavior, map viewers, freshness, p95/p99 latency, storage growth, and provider cost before setting capacity targets.

## Phases and acceptance criteria

### Phase 1 — Verify tracker prerequisites

- Confirm the admin load screen and current assignment workflow to integrate with.
- Trace a real load from upload and assignment to the salesman’s app.
- Measure valid/missing outlet coordinates and repair coordinate normalization/visibility.
- **Accept when:** every assigned outlet appears in load details; invalid pins are identified; assignment is consistent across the admin and mobile app.

### Phase 2 — Secure location backend

- Define authenticated location-ingest and latest-position/history contracts.
- Add ownership checks, validation, throttling, idempotency, indexed storage, retention, and audit events.
- **Accept when:** unauthorized and cross-distributor reads/writes are rejected, duplicate/out-of-order updates are safe, and stale positions are identifiable.

### Phase 3 — Admin live map

- Build load list, map, vehicle marker, route/stops, details panel, freshness states, timeline, and permitted history replay.
- **Accept when:** a permitted admin can track an active load and distinguish current, stale, offline, and historical positions.

### Phase 4 — Scale and resilience

- Add measured real-time fanout, autoscaling, observability, and failure handling.
- Test concurrent tracked loads, reconnect bursts, database failover, real-time channel interruption, retention jobs, and tenant isolation.
- **Accept when:** agreed freshness and latency objectives hold at a production-like workload and failures do not expose another tenant’s data.

## Decisions required before implementation

1. Which admin roles may see a salesman’s current location and replay history?
2. Should sharing run only while an assigned delivery is active?
3. Does tracking need to continue when the app is backgrounded or force-closed?
4. What location-history retention period is required?
5. Which admin panel and deployment environment should host the tracker?

## Related project references

- Mobile load, route, and location flow: [`lib/screens/auth/login_screen.dart`](../lib/screens/auth/login_screen.dart)
- Load assignment, route, and delivery APIs: [`backend/server.js`](../backend/server.js)
- Map and geolocation dependencies: [`pubspec.yaml`](../pubspec.yaml)
