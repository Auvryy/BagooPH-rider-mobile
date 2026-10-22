# Reviewing the rider map

Run these from the Rider repository root. The existing ignored configuration
supplies the Geoapify key and real Azure account endpoint; no new key or backend
deployment is required for this presentation slice.

```sh
flutter run -d linux --debug --dart-define=DEVICE_PREVIEW=true --dart-define-from-file=.env.geoapify.json
```

On PC, Home opens the Philippines/current returned stops. Use **Preview area**,
enter your chosen PH latitude/longitude, then **Show area**. For a clearly
synthetic layout check, `14.6, 121` is a public sample point in Manila, not the
rider's detected position. The map zooms to that point and retains **Manual
preview origin**. It starts no navigation and changes no parcel.

On Android, visible Home asks for foreground location once. With permission and
a fresh fix of 50m accuracy or better, it automatically frames the rider's area
at street level. Acquisition stops after that snapshot or after 15 seconds.
The location dot is labelled **Location snapshot**. Browsing, selecting a stop,
and viewing task addresses remain usable when location is denied/unavailable.
Home does not request navigation notifications.

## Interaction checks

- Pan or use +/−: the camera stays where you leave it. **Recenter** enables
  following and asks for a fresh foreground snapshot when navigation is idle.
- Select an authorized mapped pin/card: both select the same task. Missing saved
  stop coordinates keep the server address instead of a guessed map point.
- Switch the sun/moon button: dark/daylight tiles change while camera and active
  navigation remain. Native 2x artwork is selected on high-density displays;
  **Save data** switches to standard images and **Data saver on** switches back.
  The [loading extension](../map-loading-performance/README.md) owns persistent
  basemap caching and the current shared credit budget/cancellation policy.
- Explicit **Navigate**, from fresh owned task detail, retains existing vehicle,
  coordinate and authorization checks. The map follows the rider at street
  level. **Full route** fits the returned road geometry; **Queue stops** fits the
  returned mapped stops. Neither changes assignments or custody.
- Cover Home, change tabs or minimize while idle: its acquisition and tile work
  stop. Returning requests a fresh snapshot silently after a permission choice.
  Logout/access/account changes clear private in-memory location.
- A compact window or large text uses ordinary scrolling. Taller wide windows
  place work context/tasks beside the map. Provider and PH outline credits stay
  outside the map/control stack.

## Automated checks and real provider artwork

The ordinary suite uses synthetic accounts/location sources and no external
requests. It includes permission/fix/lifecycle, PH/camera, exact map controls,
tile scope/density, route and account-cleanup checks.

```sh
flutter analyze --no-pub
flutter test --no-pub
```

Optional artwork review uses the existing client key for public sample geography.
It spends provider quota, spaces requests below four per second, caches files in
ignored build output, and stops on any provider error including 429. It never
reads an account session, prints the key or saves a travelled route.

First collect the sample tile coordinates, then prepare and render the artwork:

```sh
flutter test --no-pub test/rider_map_refinement_test.dart --dart-define=MAP_RENDER=true --dart-define=MAP_ARTWORK_DIR=build/map-refinement/artwork
python3 tool/prepare_map_review.py
flutter test --no-pub test/rider_map_refinement_test.dart --dart-define=MAP_RENDER=true --dart-define=MAP_ARTWORK_DIR=build/map-refinement/artwork
```

Images and layout measurements are under `build/map-refinement/renders/`.
The accounts, parcel and route origin/destination are explicitly software-test
examples. Actual provider tiles/road geometry prove artwork compatibility, not
the rider's physical GPS or a real completed delivery.

## Physical Android checks left to the device session

- [ ] Allow foreground precise location: Home centers on the actual rider; no
  ongoing navigation notification/service starts from merely opening Home.
- [ ] Deny, permanently deny, disable services and grant approximate-only access:
  Home remains usable and reports the actual location limitation.
- [ ] Pan/zoom/recenter, background/return and logout: no stale location returns
  across the account boundary and no duplicate Home/navigation GPS stream starts.
- [ ] Start/stop an authorized coordinate-bearing route and check the existing
  screen-off/minimized navigation service on the actual phone.

These are device acceptance, deferred with the phone. Automated adapter tests
and Linux/APK builds do not mark these physical checks passed.
