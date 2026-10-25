# Leaflet delivery map and neutral rider controls

## Current scope

The user's revised direction supersedes the earlier provider-backed map design:
web and mobile both use Leaflet 1.9.4 with unfiltered standard OpenStreetMap light
tiles. The same public sample path connects a sample rider to a sample delivery
point. It is visibly labelled as an illustration, without live GPS, task IDs,
logistics hubs or a claimed delivery. Reference applications remain read-only.
The path is illustrative; it is not certified road geometry or turn-by-turn advice.

The mobile map bundles Leaflet and its BSD-2-Clause licence and runs trusted local
HTML/JavaScript through webview_all 1.4.6 (MIT). Android uses the system WebView;
Linux uses WebKitGTK 4.1. Both render the same light map, dashed red sample line,
white controls and visible attribution. Native tiles use an app-identifying user
agent and normal web-view caching. No bulk fetching, offline tile pack, map key,
external script/font download or account token enters the map document. Its CSP
allows only tile images and the local embedded scripts/styles/font. Top-level
external navigation is blocked; the fixed copyright link opens deliberately.

Map load/permission failures cannot change parcel custody or operation results.
The public sample requests no device location. Retry replaces and closes the old
renderer; hidden/disposed maps close native resources, and late callbacks cannot
restore a removed map. Web maps release their instance and resize observer when
selection/mode changes or unmounts. Saved task addresses remain available.

## Operational boundaries

The old Geoapify key and active map/routing provider are removed from ordinary
startup. The web provider endpoint is removed. Historical provider adapters and
isolated tests remain outside the active mobile import path. In-app turn-by-turn
routing is unavailable in this sample scope; actual current-stop external
directions retain their authorization/revalidation checks. The sample never
substitutes for delivery confirmation, a scan, a custody event or a dispatch route.
Existing account, duty, claim, proof, payment and recovery gates remain authoritative.

Source review: web branch through `9d8cff2`, mobile through `e3a5818`, October 25,
2026. No Azure deployment or live parcel/account/cash command was performed.

## Mobile visual direction

Shared neutral surfaces retain Bagoo red and bundled Plus Jakarta Sans. The shell
header, navigation choices, task queue filters and dispatch summary use standard
rounded controls, clear boundaries, medium labels and small neutral shadows.
The map follows the reference light style without the old dark provider tiles or
country mask. Phone pages scroll naturally; long captions grow outside the fixed
map area, including 200% text. Desktop keeps the task column beside the map.

## Verification

The local renderer runtime checks verify the OSM tile URL, sample geometry,
endpoint labels, bounded errors, attribution events and cleanup without opening
a browser. Flutter checks cover bundled document/CSP/font, key-free startup,
renderer retry, stale callbacks, lifecycle cleanup, responsive task/notification
controls, owned parcel details and absence of automatic GPS acquisition. Actual
native touch/permission/performance acceptance remains a physical-device check.
Final verification passed **631 Flutter tests with five skips**, plus both Node
renderer runtime checks. Flutter analysis found no issues. Linux and Android
debug builds passed with the key-free local rider configuration. Android emitted
an SDK XML tooling-version warning and still completed. The packaged Android
Leaflet/sample/licence assets match source, and the old map key is absent from
its Flutter assets/kernel and the Linux debug kernel. A source import audit
reached Leaflet and found no active Geoapify adapter. Earlier FlutterMap-specific
view tests were migrated to Leaflet disclosure/bridge/lifecycle coverage; legacy
provider unit tests do not prove the new renderer. No browser window, screenshot
or physical-device session was used for these checks.

Scoped map alignment assessment: **4/10 to 8/10** against the revised request;
the earlier native renderer/provider did not satisfy literal Leaflet parity.
Interface consistency: **7/10 to 8/10**, based on shared shapes/surfaces and
responsive checks, not a rendered-device assessment. Overall business-flow
readiness is unchanged. Task tracking remains pending because its existing login
expired; no saved task or measured time record is claimed.

## Local launch

```sh
flutter run -d linux --debug --dart-define=DEVICE_PREVIEW=true --dart-define-from-file=.env.rider.json
```

Run from the mobile repository. The ignored file preserves only existing accepted
feature configuration; maps need no key. If absent, omit that argument without
enabling unverified operations. Neither the configuration nor old map credentials
are published. Separate PR descriptions are local drafts; the user publishes.
