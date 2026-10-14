# HDB-02 navigation lifecycle and map-loading evidence

October 13–14, 2026. Branch `fix/home-navigation-lifecycle`, based on merged mobile
`main` `7a5dbe8` (HDB-01/PR 17). Only this lifecycle slice and the user's map-loading
investigation/future recommendation are activated.

## Result

Normal GPS-stream completion and stream errors clear the task, fix, road, timers
and active state. Old stream/route callbacks cannot restore them. A newer Navigate
also wins when an older native stream cancellation is slow. Pauses retain only
the task identifier needed for explicit revalidation; revalidation checks access
without preparing or starting location updates. Its reason/action remains visible
outside Home and in constrained views. Account/task access loss clears paused
targets too. Sedan / Van maps to driving while registered-profile precedence and
explicit unknown-vehicle selection remain intact.

Home receives its actual tab/foreground visibility from the shell. A hidden Home
unmounts its map, cancels that tile scope and schedules no view-driven camera
updates; the persistent rider-started navigation controller continues. Camera
center/zoom/rotation and manual pan survive return and keyboard resizing.
Recenter restores following explicitly. Initial loading waits for current-stop
data before requesting tiles, avoiding discarded overview tiles for a known task.

Tiles use Geoapify's documented map host with an image Accept header; routing
keeps the API host. The dedicated client sends no Bagoo bearer and keeps the
existing four-request/second scheduler and 128-tile memory cache. A cancelled old
request cannot poison a new request for the same tile. Decoder keys separate view
scopes/retry revisions; failed decoding removes bad cached bytes even when a
sibling tile has already failed. A healthy tile
does not dismiss a failed sibling, and discarded-view failures do not latch onto
the next view. Connection,
send and receive waits are bounded. Loading/failure/address/manual-preview notes
sit outside the streets, with visible attribution and an explicit cooldown-aware
retry limited to once per 30 seconds. No automatic retry loop or substitute roads
are introduced.

## Source and live evidence

Website checkout observed `b14a2bf` on `feat/pickup-handover-recovery`, with its
owner's work in progress. Reviewed native task/controller/contract, registered
vehicle vocabulary, courier flow/roadmap and the relevant handover changes read
only. The work adds hold-aware pickup eligibility/version/action hints; the native
resource still returns coordinates only for owned buyer stops. No backend file,
branch, database, migration, test or deployment was changed by this mobile work.
The inspected OpenAPI remains version 1.0.0/25 operations/24 paths and SHA-256
`8b09acf2e933441ee766820c94f65eafe1240c6c343b659e89487c6ab1e507eb`.
Uncommitted owner work is not treated as deployed/accepted native integration.

At subsequent inspection, the owner advanced to clean `9929d14` on the same branch.
The reviewed hold/version/action changes are now in that source revision; the
OpenAPI fingerprint remains unchanged. This is source observation, not a fresh
Azure deployment or acceptance of a new native handover workflow.

The October 14 completion review observed `7d1790b` on
`feat/hub-handover-recovery`, with unrelated hub receipt/model/migration work in
progress. The native task service and OpenAPI have no change from `9929d14`;
the same fingerprint remains. The owner's work was preserved read only.

Two direct HTTPS requests used only the existing private provider key and one
public Manila tile, not a rider fix or task. Both returned HTTP 200 with a valid
70,130-byte PNG: approximately 2,906 ms through the previous API host and 1,365 ms
through the documented map host. These sequential samples establish reachability,
not a controlled speed comparison or full phone performance. The provider tile
was inspected; the current style remains intentionally light/neutral. No key,
Bagoo bearer or real account/task data entered logs or tracked artifacts.

Reference: [Geoapify map-tile documentation](https://apidocs.geoapify.com/docs/maps/map-tiles/).
Custom-provider cache scope was checked against
[flutter_map's caching guidance](https://docs.fleaflet.dev/layers/tile-layer/caching)
and the installed 8.3.2 implementation.

## Verification and remaining limits

Maintained checks cover stream completion/error, slow cancellation, pending/late
road geometry, registered profile precedence, explicit paused revalidation and
denial, cache reuse, cancellation/retry scope, actual timer-based quota recovery,
host/header/bearer isolation, hidden Home with active fixes, saved pan/Recenter,
keyboard map removal, attribution and bounded retry. Existing HDB-01, account,
Settings, operations/transport and navigation regressions remain required.

Final `flutter test --no-pub --reporter expanded`: **179 passed**, one expected
configuration skip. `flutter analyze --no-pub`: no issues. Ordinary Linux release
and ARM64 debug APK builds pass on the final runtime source with the existing
private map configuration. Work writes remain
disabled and the ordinary account service remains Azure HTTPS.

No Android device was detected. Actual GPS/notification, permission changes,
screen-off/minimized continuation and physical touch/performance remain open.
No fresh Azure operational login/mutation, fixture production mode or automatic
tracking was used. Global/backlog/physical readiness is not marked complete.

The country-shaped restriction and expanded current-stop presentation remain the
separate [Philippines map recommendation](PH_MAP_FOCUS_NEXT.md). They are not
claimed as implemented by this lifecycle branch.
