# Configuration and remaining acceptance

Ordinary launches and APKs continue to use the deployed Azure account service.
There is no fixture account, automatic login or production sample dashboard.

## Provider configuration

The selected project-local file is `.env.geoapify.json` in the Rider project
root. It is private, ignored by the existing `.env.*` rule and must remain
untracked. Supply it with `--dart-define-from-file=.env.geoapify.json` on run/build.
Example file contents:

```json
{
  "GEOAPIFY_API_KEY": "<dedicated-client-key>",
  "OPERATIONS_WRITES_VERIFIED": true
}
```

The true operations flag applies to the accepted Azure profile documented below;
unverified environments keep it false. Handover activation is a separate flag.
Keep real keys out of source, screenshots, logs and commits. This key remains
extractable from an installed application and is not a protected server secret.
A dedicated key has now been supplied privately and verified against real tiles
and routing through the Flutter client. Missing configuration still keeps task
addresses and real account access usable; the app does not invent tiles/routes.

The [October 22 loading extension](../map-loading-performance/README.md) supersedes
the original four-request/second scheduler with a rolling four-credit/second
budget shared by tiles and routes, navigation priority and six active requests.
Tiles cost one-quarter credit; route calls cost one. It retains 128 memory tiles
and adds a native 64 MiB basemap disk cache, with freshness and provider cooldowns.
A 429 or denied key/quota yields a visible provider failure; route failure removes
stale geometry. The free plan currently advertises 3,000 shared credits/day; verify
usage in the provider project before rollout. [Pricing](https://www.geoapify.com/pricing/),
[routing parameters](https://apidocs.geoapify.com/docs/routing/),
[required map attribution](https://apidocs.geoapify.com/docs/maps/map-tiles/).
All three credits (Geoapify, OpenStreetMap and OpenMapTiles) stay directly below
the map, clear of task content and bottom navigation. On phones they scroll with
the map; the task section uses the same normal page scroll.

Dependencies reviewed October 9: flutter_map 8.3.2 (BSD-3-Clause, native Linux/
Android), geolocator 14.1.1 (MIT, Android foreground-service configuration) and
latlong2 0.10.1 (Apache-2.0). The repository SDK resolves them through pubspec.lock.
Primary references: [flutter_map](https://pub.dev/packages/flutter_map),
[geolocator](https://pub.dev/packages/geolocator).

## Backend-owner handoff

October 16: [HDB-05 native verification](../home-dashboard-branch-plan/HDB-05-EVIDENCE.md)
passed against owner-verified Azure revision `c262473`, with current migrations
and an authorized isolated pickup. Native Home/queues/detail, explicit duty,
one claim, original-key replay, protected-intent recovery and stale/changed-body
rejection passed. The owning website's 04:41 UTC post-check passed all 20 checks,
matching the native commands and single assignment with seller custody intact.
Final review enables duty/claim in the existing ignored local build profile.
The shared default remains disabled; handover writes and physical Android
acceptance stay separate. The accepted local builds are rebuilt with that profile.

Before enabling `OPERATIONS_WRITES_VERIFIED`, obtain and record:

1. Actual deployed commit compared with backend source `1d785aa`, and verification
   that no source migrations are pending, including
   `2026_10_09_010000_create_rider_commands_table`. Do not reset/reseed production.
2. Fresh authorized rider token with operations abilities and account discovery
   `operations_api_version: 1`. A restored older token may need ordinary sign-in.
3. HTTPS JSON Home, available pickups, owned pickup/final-mile queues and current
   task detail; scope, no-store/privacy headers and denied/hidden access checks.
4. Authorized duty and claim through the native client, observed in the website.
   Confirm competing/stale claims cannot assign twice and interrupted writes
   reconcile/replay the original key/body. Record safe request IDs, not tokens.

The app defaults to disabled production duty/claim writes. The accepted local
Azure profile now explicitly sets the flag true after these checks; other
configurations require their own acceptance. Read-only Home connects when the
approved account discovers version 1.
The flag is a release acceptance gate, never a substitute for server authorization.
It does not change account approval, placement, capability or capacity checks.

For a Linux launch with the saved key:

```sh
flutter run -d linux --debug --dart-define=DEVICE_PREVIEW=true --dart-define-from-file=.env.geoapify.json
```

For an Android debug build with the saved key:

```sh
flutter build apk --debug --dart-define-from-file=.env.geoapify.json
```

Existing builds must be rebuilt to receive changed compile-time configuration.

Current task source returns coordinates only for buyer stops. Seller and hub
stops remain address-first. Backend ownership must decide any future coordinate
sources; this client never geocodes or guesses missing destinations.

## Linux and Android acceptance

On Linux, select a revalidated owned task with coordinates and enter a valid,
explicitly labelled manual preview origin. Registered motorcycle/scooter/sedan/van
uses its matching profile; unknown vehicles require an explicit profile choice.
Press Navigate, test road geometry with a real provider key, panning/Recenter,
manual refresh/cooldown, missing coordinates and provider failures. Linux does
not start GPS tracking or demonstrate Android background navigation.

On a physical Android phone, start Navigate while the app is visible. It requests
precise foreground location and notification permission contextually and starts
geolocator's location foreground service with an ongoing notification and wake
lock. Dashboard browsing remains available when permissions are denied.
No background-location, boot receiver or duty-triggered tracking is requested.
The visible-start service model follows [Android foreground-service guidance](https://developer.android.com/develop/background-work/services/fgs/restrictions-bg-start).

Verify actual fixes and screen-off/minimized updates, notification, explicit Stop,
restart/revalidation, permission removal, logout/account change, reassignment and
changed destination. Authorization refresh runs every minute; an independent
two-minute deadline pauses tracking if access cannot be refreshed. Stop cancels
the stream, timers and pending route. No travelled-location history is persisted
or uploaded to Bagoo, and proximity performs no parcel action.

Voice guidance uses an explicitly launched external directions app. The in-app
surface shows the rider, target and remaining road line. No multi-stop optimizer
or voice engine is included. No survival after force-stop is promised; navigating
again requires a rider action. An APK build/mock route is not physical acceptance.
