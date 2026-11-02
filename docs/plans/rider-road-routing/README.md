# Rider road routing

The November 2 request selects real road lines for assigned Rider stops. It
supersedes the sample-only routing decision for this scope. The map remains
OpenStreetMap-based, with an explicitly started and disclosed route request.

Reviewed Rider main: `efbfed3`. Reviewed Bagoo web location branch: `ce98a8b`,
based on main `c55046c`; its seller and hub stop-pin changes are local source,
not evidence of deployment. Existing Rider task authorization and custody
rules remain authoritative. No location history is stored or sent to Bagoo.

Work proceeds in three parts: verify provider geometry and endpoints; connect
an opt-in configured road provider to the existing navigation controller; and
show its current authorized route in the mobile map. Missing configuration,
coordinates, permissions or valid provider results must not produce a fake
line. Keep request cancellation and task/account lifecycle handling intact.

PC verification uses serial Flutter tests and the bundled map renderer tests.
Actual provider credentials, deployment, Android GPS, permissions, lifecycle and
physical-device map acceptance remain open. The local work tracker was
unavailable; no remote task or timer is claimed.

Route-integrity milestone: 18 focused Geoapify and navigation tests passed on
the PC, including rejection of mismatched endpoints and disconnected sections.
The route provider now activates only when the build-time public client key
`GEOAPIFY_API_KEY` is supplied; use a provider-restricted key and never treat a
mobile build setting as a secret. With no key, external directions remain
available. Navigation requires an explicit rider action and discloses the
coordinates sent to the provider. Android declares the location foreground
service and its required permissions; GPS and notification access are requested
when navigation starts, not when opening the map.

The authorized Stop Mode map can now draw, update and clear the current road
line. Its Leaflet renderer receives validated geometry through a local bridge;
the Linux map uses the same route data. The route is removed when its task no
longer matches or navigation stops. Focused PC tests cover both renderers,
provider configuration, route lifecycle, assignment changes and failures.
These checks do not establish that Android permissions, service lifecycle,
real provider access or deployed stop coordinates work on a device.

A separate PC contract test starts navigation for an authorized stop through
the actual Geoapify client with a synthetic HTTP response, checks the requested
endpoints and resulting line, and confirms Stop clears it. This does not use a
real provider key or prove production route availability.

The route controller also discards a response if the rider has moved at least
50 metres since its request, clears the line after two off-route fixes, and
removes it when the latest GPS fix expires. Navigation and lifecycle checks
passed 28 tests; targeted analysis passed. Actual movement, timing and GPS
accuracy remain physical-device acceptance items.

Road responses are streamed with a 2 MB limit and a response deadline before JSON
decoding. Rejected or cancelled downloads release their network stream without
cancelling the rider's outer navigation token. The provider, navigation and
map-loading PC suites passed 45 tests, including the cancellation case, and
targeted analysis passed. This limits the
memory used by a single route response; actual device performance remains open.

PC evidence: 63 provider/navigation/Stop Mode/map tests, 41 additional
navigation and Home lifecycle tests, 6 embedded-map tests after the display
failure safeguard, and 5 bundled renderer runtime checks passed. Flutter
analysis passed. A single-worker Android debug manifest merge passed and the
merged manifest contains the foreground location service and its required
location, notification and service permissions; it does not request background
location permission. No application window, device, real provider request or
live parcel action was used.

See the [task map](../../TASK_TRACKING.md), [backlog](../../SUBTASK_BACKLOG.md)
and [source rules](../../SOURCES.md) for existing dependencies and evidence.
