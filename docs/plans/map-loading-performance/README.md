# Faster map loading with the existing design

Selected October 22, 2026, on `feat/home-rider-map-style` at `dcb4252`.
Estimate: **6 client hours**, October 22–24, Asia/Manila. State: **implemented
and locally verified**; results belong in [verification](VERIFICATION.md).
Physical phone timing remains a separately listed follow-up.

This is the requested loading extension of [rider map refinement](../rider-map-refinement/README.md),
[OPS-01](../home-dashboard-navigation/README.md) and [M09.07](../../backlog/M09.md#m09-07).
The [task map](../../TASK_TRACKING.md), [source rules](../../SOURCES.md) and
[delivery plan](../../DELIVERY_PLAN.md) retain their original scope.

## Selected behavior

- Keep flutter_map 8.3.2 and Geoapify, the dark/daylight palette, PH outline,
  readable route, pins, attribution, foreground rider snapshot, deliberate
  camera gestures, normal scrolling and address fallback.
- Add a native basemap cache in the OS application-cache directory: 64 MiB
  maximum, 2 MiB maximum per encoded tile, atomic writes, serial asynchronous
  access and bounded eviction (recently used order in memory, file modification
  order when reopening). The OS may clear it. No guaranteed offline
  region is advertised. Invalid/expired files fall back to provider requests.
- Cache only public basemap image bytes and expiry timestamps under hashed
  style/density/XYZ keys. Never persist API keys, bearer tokens, account/task
  data, route geometry, GPS samples or travelled-location records.
- Fresh memory/disk hits bypass the network scheduler. Honor no-store/no-cache,
  max-age/Age, Date/Expires; use seven days when freshness is absent and cap
  freshness at thirty days. Decode failures invalidate both cache levels.
  Disk failure or a 250 ms storage timeout leaves network maps usable. Cache
  writes run after bytes are available for first paint.
- Replace the original four-requests/second policy with a **rolling four-credit
  budget per second**: a tile costs 0.25 credit and a route costs one. Space
  starts by at least 75 ms and allow at most six active requests. Navigation
  precedes queued tiles; retain flutter_map's centre-first tile order and
  cancellation, deduplication, 429/key cooldowns and explicit retry.
- Keep native 2x tiles as the sharp default on dense displays. Replace the HD
  icon with a labelled **Save data / Data saver on** toggle for standard tiles.
  Preserve the camera, selected task, route and navigation when toggling.

The provider budget is per app instance, not an account-wide limiter. Multiple
devices and other clients share the same key/account allowance. This does not
authorize bulk downloading, request storms, paid upgrades or new backend work.

## Dependencies and decisions

Existing crypto, path_provider, Dio and flutter_map are sufficient; no dependency
upgrade or new key is needed. Flutter Map's built-in disk cache was inspected:
its documented size reduction runs at instance creation and can exceed its
budget during a session. This slice instead uses small bounded atomic files in
the existing separate Geoapify transport, preserving cancellation and quota
handling. It is not a renderer migration. Vector tiles and MapLibre remain
possible later experiments, after this measured baseline.

Read-only backend review: `99e5895f98159334e372df4f43659fda0bd43960` on
`fix/logistics-page-reliability`; courier flow, roadmap, native operations API,
RiderTaskService and operations tests. Only frozen buyer stops have native
coordinates; seller/hub coordinates remain null. No Azure write, account or
parcel mutation, deployment or physical-device acceptance is part of this slice.

## Review

1. Browse Home in dark/daylight styles; verify street labels, pins, route and
   attribution remain readable at phone, landscape and desktop sizes.
2. On a dense display, tap Save data. Standard images load; Data saver on exposes
   the current state. Tap again for sharp labels. Panning/follow/route must stay
   unchanged.
3. Revisit a viewed area, including after a process restart. Fresh cached
   basemap tiles should need no network call. An uncached area still needs
   connectivity; task addresses remain available on failures.
4. Check corrupt/expired cache, storage failure, cancellation, mixed route/tile
   budgets, concurrency, provider cooldown and disposal in automated tests.
5. Compare the old 260 ms request queue to the weighted queue under the same
   controlled provider latency. Report requests, bytes and elapsed time for cold,
   memory-warm and disk-warm loads. This is software evidence, not phone timing.
6. Run analysis, relevant/full tests, actual provider-artwork layout review and
   ordinary Linux/Android builds. Real Android profile-mode timing remains a
   separate physical-device check; never infer it from desktop debug performance.

Run from the Rider repository root for the PC phone view:

```sh
flutter run -d linux --debug --dart-define=DEVICE_PREVIEW=true --dart-define-from-file=.env.geoapify.json
```

## Primary references

- [Geoapify pricing](https://www.geoapify.com/pricing/) and
  [credit accounting](https://www.geoapify.com/pricing-details/) — free plan
  five general requests/s, fourfold tile allowance, quarter-credit tiles.
- [Tile caching policy](https://www.geoapify.com/map-tiles/) — caching is allowed,
  attribution stays required.
- [Flutter Map cache API](https://pub.dev/documentation/flutter_map/latest/flutter_map/BuiltInMapCachingProvider-class.html)
  and installed BSD-3-Clause 8.3.2 implementation — custom-provider caching and
  built-in cache size semantics.
- [Flutter profiling](https://docs.flutter.dev/perf/ui-performance) — profile mode
  and physical-device evidence for runtime claims.
