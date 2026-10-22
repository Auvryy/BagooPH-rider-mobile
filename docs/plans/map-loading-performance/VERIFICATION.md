# Map loading verification

Reviewed October 22, 2026 against the implementation in the [selected plan](README.md).
Local runtime checks, artwork review and both native builds passed. No
physical-device timing is claimed.

## Controlled loading measurements

The comparison uses the same 20 unique tile keys, a recorded public Geoapify PNG
of **61,025 bytes**, and a Dio adapter with **200 ms simulated response latency**.
The previous production scheduler is reproduced only inside the benchmark.
There are no external requests, real riders or parcel mutations in this check.
Elapsed times cover obtaining the tile bytes; they exclude image decoding,
painting, GPS acquisition, Azure queues and real network variability.

| Case | Time | Network requests | Network bytes |
|---|---:|---:|---:|
| Previous queue, cold | 5,159.394 ms | 20 | 1,220,500 |
| Weighted queue, cold | 1,668.115 ms | 20 | 1,220,500 |
| Current client, memory warm | 1.199 ms | 0 | 0 |
| New client/cache objects, disk warm | 25.012 ms | 0 | 0 |
| Separate process, disk warm, offline adapter | 64.867 ms | 0 | 0 |

Cold loading was about **3.1 times as fast in this controlled comparison**.
Fresh disk reuse was independently checked by another process using the persisted
files and an adapter that would fail any network request. This proves cache reuse
and software scheduling gains, not a universal Android loading time. The current
comparison peaked at three active requests; deterministic tests separately prove
the six-request ceiling and rolling mixed-traffic budget.

Reproduce without any account or key:

```sh
flutter test --no-pub test/map_loading_benchmark_test.dart --dart-define=MAP_BENCHMARK=true
flutter test --no-pub test/map_loading_benchmark_test.dart --dart-define=MAP_BENCHMARK=true --dart-define=MAP_BENCHMARK_RESTART=true
```

The default uses a small valid PNG. To reproduce the recorded payload size,
prepare the public artwork through the existing
[artwork helper](../../../tool/prepare_map_review.py), then add
`--dart-define=MAP_BENCHMARK_ARTWORK=build/map-refinement/artwork/dark-matter-dark-grey/15-27399-15040.png`
to both commands. Outputs stay in ignored `build/map-loading/`; these commands
clear only their own generated benchmark-cache directory on the first run.

## Checks and acceptance

| Requirement | Current evidence |
|---|---|
| Persistent bounded files | Real filesystem tests reopen a new cache/client; strict byte eviction, interrupted files, corrupt headers, slow initialization and failure fallback pass |
| Freshness and privacy | Expired memory/disk replaced; no-store/no-cache/max-age/Age/Expires honored; decode failures invalidate both caches; filenames hashed and raw synthetic key absent |
| Priority and quota | Route priority, cancellation, 4-credit rolling mixed traffic, six active calls, pending-queue denial/recovery and disposal tests pass; fresh cached tiles remain usable during cooldown |
| Design preserved | 11 artwork checks pass over cached real provider tiles/road geometry: dark/daylight, phone/landscape/desktop, 200% text, reduced motion, PH focus, route/camera and attribution |
| Data-saving control | Native 2x remains the dense-display default; labelled 48dp toggle switches standard images, preserves camera/navigation, and exposes its on state and label to semantics |
| Regression | Full suite: **584 passed, five skipped**, terminal `All tests passed!`; four existing opt-in skips plus the separately executed benchmark |
| Analysis | `flutter analyze --no-pub`: **no issues** |
| Linux/Android builds | Both ordinary debug builds passed, with the existing private map configuration; Linux also includes the PC phone-frame flag |

The benchmark runs twice as opt-in checks, one per process. The map artwork suite
also runs separately with `MAP_RENDER=true` and the prepared artwork directory.
All checks use the same source fingerprint; their logs and receipts remain in
ignored build output. No dependency or private configuration changed.

## Physical follow-up

- [ ] On an Android phone, profile first-open, repeat-area and process-restart
  loading on Wi-Fi and mobile data; collect time to readable streets, transferred
  bytes and slow frames. Compare normal and data-saving modes at the same place.
- [ ] Check denied location permission and first GPS acquisition separately from
  map download time. Verify minimized/return behavior with the existing navigation
  notification and explicit Stop control.

These are deferred device observations, consistent with the user's phone
deferral. They are not represented by desktop layout tests or APK compilation.
Existing Azure access, owned-stop authorization, missing seller/hub coordinates
and explicit navigation lifecycle remain governed by their original plans.
