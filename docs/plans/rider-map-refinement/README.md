# Rider map refinement and foreground location

Selected October 22, 2026 on `feat/home-rider-map-style`, from merged mobile
`main` `b19a437`. Estimate: **6 client hours**, October 22–24, Asia/Manila.
State: **implemented and locally verified**. See the
[review instructions](TESTING.md) and [verification evidence](VERIFICATION.md).
The deferred physical Android checks remain explicit in the review instructions.
The follow-on [map loading extension](../map-loading-performance/README.md) owns
persistent basemap caching, credit-aware scheduling and the data-saving control.
This is a bounded visual/location extension of
[OPS-01 and the map/location plan](../home-dashboard-navigation/README.md),
[M09.07](../../backlog/M09.md#m09-07) and the merged
[Philippines map focus](../philippines-map-focus/README.md).
The [task map](../../TASK_TRACKING.md), [source authority](../../SOURCES.md),
[Home branch plan](../home-dashboard-branch-plan/README.md) and
[delivery deadline](../../DELIVERY_PLAN.md) retain their existing scope.

## Selected behavior

- A charcoal Geoapify basemap, readable outlined route, clear stop/rider markers,
  labelled 48dp controls and a daylight style. Preserve normal Home scrolling,
  visible provider credits and textual task/address fallback.
- Open within the Philippines display. Automatically obtain a bounded foreground
  location sample on visible Android Home, subject to foreground permission.
  A valid fresh sample frames the rider's area at street level. Permission denial,
  services off, timeout or an outside-country sample keep browsing usable.
- Sampling stops after a good fix, on timeout, when Home is covered/backgrounded,
  on account/access changes and before navigation takes over the shared GPS
  stream. It never requests notification permission or starts a location
  foreground service. Only explicit Navigate starts continuous navigation.
- Panning/zooming suspends camera follow until Recenter. Selection, full-route
  framing and queue overview remain deliberate controls. Navigation follows the
  rider at street level; the full route stays available separately.
- Linux retains an explicitly labelled manual preview origin, with an optional
  coordinate entry for inspecting an area. No IP-derived or invented rider fix.
- No travelled-location storage/upload, new provider key, new endpoint, road
  condition dataset, custody/claim/outcome command or backend change.

## Prerequisites and source review

The existing auth/session, PH outline, provider scheduler, cancellation/cooldown,
road geometry, task authorization and navigation lifecycle are merged. The user
selected this visual/location enhancement directly; it does not activate a new
parcel workflow or close the full M09/Android gates.

Read-only backend review: `99e5895f98159334e372df4f43659fda0bd43960`, on its
maintainer's `fix/logistics-page-reliability` branch. Reviewed courier flow,
roadmap, native operations contract, `RiderTaskService`, and operations tests.
Native buyer stops still use frozen checkout coordinates; seller/hub stop
coordinates remain null. No coordinate is guessed or copied from web-only data.
This presentation work requires no new deployment; it does not establish a new
Azure or physical GPS acceptance result.

## Implementation and finish evidence

1. Add an account-scoped foreground map-location controller and coordinate
   navigation handoff without overlapping geolocator streams.
2. Refine map palette/chrome, density, markers and camera behavior.
3. Verify permission/fix/lifecycle cancellation, PH/camera/pan/recenter behavior,
   actual provider artwork, responsive and large-text/reduced-motion layouts,
   analysis, Flutter regression tests and ordinary Linux/Android builds.
4. Record exact results in [VERIFICATION.md](VERIFICATION.md), including the
   boundary between automated native-adapter tests and a physical phone check.

The foreground snapshot and visual/camera changes are implemented. Review
uses real provider artwork over software-test accounts and fixed public sample
geography. Ordinary builds retain Azure login and their existing command gates.

## References

- [Geoapify styles and attribution](https://apidocs.geoapify.com/docs/maps/map-tiles/)
  — existing `dark-matter-dark-grey` and daylight raster tiles, including native 2x.
- [Geolocator](https://pub.dev/packages/geolocator) and the installed plugin's
  Android stream implementation — foreground permission, cancellable stream,
  and notification configuration are separate concerns. No dependency upgrade.
- [flutter_map](https://docs.fleaflet.dev/) and installed 8.3.2 sources — camera
  constraints, overlays and geometry remain in Flutter.

Run from the Rider repository root for the PC phone frame:

```sh
flutter run -d linux --debug --dart-define=DEVICE_PREVIEW=true --dart-define-from-file=.env.geoapify.json
```
