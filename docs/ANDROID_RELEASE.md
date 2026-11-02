# Android release packaging

Ordinary debug APK builds keep the existing scaffold application ID when no
release ID is configured. Release APK/AAB packaging requires an approved package
ID and a local signing key; the build never falls back to the Android debug key.
At Rider revision `e0aa20e`, a PC release-build request stopped before artifact
generation because the approved ID and all local signing settings were absent.
This verifies the fail-closed guard; it is not release-build acceptance.
The November 2 configuration check found `RIDER_APPLICATION_ID` unset and
`android/key.properties` absent. No release APK was produced in this follow-up.

## Latest PC build artifacts — November 2, 2026

The latest recorded arm64-targeted debug APK was built on the PC from Rider commit
`92fc7c0` on `fix/rider-route-privacy-disclosure`, with
`RIDER_DEBUG_CLEARTEXT=false`. It includes the app-level
inactive-state Flutter cover and pause-scoped Android `FLAG_SECURE` handling.
It also includes the onboarding button typeface correction.
The focused cover test passed 1/1, and `:app:compileDebugKotlin` succeeded with
one worker and a 768 MiB heap cap. The restricted APK build completed in 56.2 seconds with
one Gradle worker and a 1 GiB heap cap. It emitted nonfatal SDK XML and Gradle
deprecation warnings. The ignored `.env.rider.json` supplied the existing Rider
build profile; no API override or local-auth define was added.

| Variant | Source | Size | SHA-256 | Verification |
|---|---|---:|---|---|
| Latest recorded restricted debug | `92fc7c0` | 176,230,585 bytes | `3b5aec59fd49ce1401c43e224c886920951e22302e9c60fc0ca2e349e4e364c3` | ZIP integrity; package/SDK metadata; ARM64 Flutter engine; APK v2 signature; backup and cleartext disabled; no location, notification or foreground-service permissions |
| Earlier debug | `05bca09` | 176,230,585 bytes | `6f4f568fbf3c7b5e09487643e0fc14d23aa33299bf201661d132c80bafe4e74f` | Superseded; debug manifest permits cleartext |
| Earlier debug | `18759ce` | 176,230,447 bytes | `7ead0ffb97ff7785ff2c8dfe61afadf3a978336d9441acb59b0322df5c20e9bc` | Superseded; predates onboarding typography correction |
| Earlier debug | `daacf85` | 176,228,861 bytes | `215a1275cc6e4b83a7dce8a39e3d5a493cdecfd9391f91d1114e61af139e6d61` | Superseded; predates inactive-state privacy changes |
| Profile | `ba7823a` | 77,671,976 bytes | `f6334ab298f784444a5ae905372a274eb79e0df7f8d2a1280d7852bd90ac68a5` | Earlier ZIP integrity; package/SDK metadata; ARM64 engine; APK v2 signature; location-service permissions absent |

All artifacts use package ID `com.example.bagoo_rider_mobile`, version `0.1.0`
(code 1), minimum SDK 24, and target SDK 36. The latest recorded debug APK has one
standard Android Debug signer and verifies with APK Signature Scheme v2. It is
debuggable and is not a distributable release artifact. It was not installed or
launched; no phone, ADB, or emulator was used. The archive and signature checks
do not establish actual Android app-switcher behavior, Azure, or production
cross-role acceptance.

The merged manifest in the latest restricted debug APK disables application
backup and sets `usesCleartextTraffic=false`. An ordinary debug build without
the restriction sets it to `true`; that platform setting permits cleartext
traffic and is not a localhost-only Android restriction.
Separately, the Rider API origin validator accepts HTTP only for an explicitly
enabled debug local-auth configuration on an allowed loopback host. The build
profile recorded here does not enable local authentication and uses HTTPS for
the Rider API. The merged manifest is build evidence; actual device network
behavior and the signed release manifest still need verification.

For an Android debug build that rejects cleartext at the platform level, set
`RIDER_DEBUG_CLEARTEXT=false` in the build environment. The default remains
`true` for the existing debug development workflow; only `true` and `false`
are accepted. The restricted build cannot use the local HTTP API configuration.
The effect on Flutter debugging and actual Android network behavior still needs
physical-device verification.

The ordinary and restricted debug builds both compiled with one Gradle worker;
their merged manifests were checked as `true` and `false`, respectively. Rebuild
the restricted debug APK with:

```sh
RIDER_DEBUG_CLEARTEXT=false flutter build apk --no-pub --debug \
  --target-platform android-arm64 --dart-define-from-file=.env.rider.json
```

A separate one-worker `:app:processDebugMainManifest` check with an invalid
`RIDER_DEBUG_CLEARTEXT` value failed during configuration with the expected
validation error; the restricted APK hash remained unchanged.

At branch commit `c7aa1bb`, a one-worker `:app:processReleaseMainManifest`
check succeeded with a 512 MiB heap. The generated release application
manifest sets `allowBackup=false` and `usesCleartextTraffic=false`, so the
debug override is absent from that merged manifest. This check did not package
or sign an APK and does not verify device network behavior. The final signed
artifact's manifest remains a separate release check.

The current merged manifest contains Internet, camera, AndroidX network-state,
and the standard non-exported receiver permission. It does not contain
location, notification, or foreground-service permissions, and the geolocator
service is excluded. The Home location
controller is not connected to the default Home surface. `roadRoutingProvider`
is `UnavailableRoadRouting`, so the Navigate control and foreground route
session cannot start through the default UI. The dormant navigation
implementation needs an explicit manifest/permission review and physical
acceptance before a future build can enable it.

The local build file set only `OPERATIONS_WRITES_VERIFIED=true`; it supplied no
API override or local-auth flag. `AppConfig` therefore uses the default deployed
HTTPS API, whose string is present in both compiled APK payloads. Under the
accepted [HDB-05 profile](plans/home-dashboard-branch-plan/HDB-05-EVIDENCE.md),
that flag enables duty and pickup claims only. Parcel, paid delivery, cash,
messages, notifications and handover write gates remain false. This confirms
build configuration, not current service availability or live transaction
acceptance. Use only an approved rider and isolated owned resources for any
future live rehearsal.

The defense-profile configuration check passed **1/1** with the same local
build file. It asserts the deployed origins, disabled local authentication,
enabled duty/claim gate, and disabled parcel, Wallet, cash, message,
notification and handover write gates. It does not contact the deployed API.
The ordinary suite skips this profile-specific check unless explicitly enabled:

```sh
flutter test --no-pub --concurrency=1 --reporter=compact \
  --dart-define-from-file=.env.rider.json \
  --dart-define=VERIFY_DEFENSE_PROFILE=true test/defense_build_profile_test.dart
```

The build-profile activation test passed **2/2** serially with the same local
configuration. Its fake server confirms the duty control and pickup-claim
follow-up behavior; it does not send requests to the deployed API:

```sh
flutter test --no-pub --concurrency=1 --reporter=compact \
  --dart-define-from-file=.env.rider.json \
  test/operations_activation_test.dart
```

On November 2, a PC read-only request to `/api/v1/rider/home` returned HTTP
401 JSON without a redirect, with `Cache-Control: no-store, private` and
`Pragma: no-cache`. This confirms the deployed HTTPS route responds and keeps
the unauthenticated response private; it does not test sign-in, an approved
account, or operational commands.

## Earlier arm64 debug APK record (commit `94d2aaf`)

At Rider branch head `94d2aaf` (runtime `30412ed`), this PC-only build produced
an earlier arm64-targeted debug APK:

```sh
flutter build apk --no-pub --debug --target-platform android-arm64 \
  --dart-define-from-file=.env.rider.json
```

The output is `build/app/outputs/flutter-apk/app-debug.apk`, 176,219,115 bytes,
with SHA-256
`60048103e9969765b7ec3237957a6bca45d368ce850cbd6c29d14645ba6e9d23`.
The ZIP archive passed integrity checks. `aapt` reports package
`com.example.bagoo_rider_mobile`, label `BagooPH Rider`, version `0.1.0`
(code 1), min SDK 24 and target SDK 36; the manifest marks it debuggable.
The debug kernel asset and `arm64-v8a` Flutter engine are present. Plugin
libraries also include `armeabi-v7a` and `x86_64`. `apksigner verify --verbose`
confirmed one signer and APK v2 signing with the standard `Android Debug`
certificate. It is not a distributable release and was not installed.

## Earlier arm64 profile APK record (commit `94d2aaf`)

At Rider branch head `94d2aaf` (runtime `30412ed`), this PC-only profile build
produced an earlier arm64-targeted preview:

```sh
flutter build apk --no-pub --profile --target-platform android-arm64 \
  --dart-define-from-file=.env.rider.json
```

The output is `build/app/outputs/flutter-apk/app-profile.apk`, 77,671,976 bytes,
with SHA-256
`b43c41ffa07ab9e459843fd1b5ca67c51dff6bbc1d6d6c8d89f539f6bfa1bd54`. The
ZIP archive passed integrity checks. `aapt` reports package
`com.example.bagoo_rider_mobile`, label `BagooPH Rider`, version `0.1.0` (code
1), min SDK 24 and target SDK 36; the profile manifest is debuggable. The
arm64 `libapp.so` is present, and plugin libraries include `arm64-v8a`,
`armeabi-v7a` and `x86_64`. `apksigner verify --verbose` confirmed one signer
and APK v2 signing with the standard `Android Debug` certificate. This is a
performance-preview build with the scaffold ID and debug signing, not a
distributable release. It was not installed and does not establish Android
device acceptance. Older profile builds are historical.

## Local configuration

Set `RIDER_APPLICATION_ID` to the package ID approved for this project, for
example through the shell environment used for the release build. It must be a
valid Android application ID and must not use the `com.example` scaffold.

Create the ignored file `android/key.properties` with these four properties:

```properties
storeFile=release-key.jks
storePassword=
keyAlias=
keyPassword=
```

Keep the keystore file outside version control. A relative `storeFile` path is
resolved from the `android/` directory. The properties file and keystore are
already ignored by Git; never commit either file or put their values in logs,
task descriptions, or source code. Replace the three empty values locally.

## Build

After configuring the approved ID and local signing files, run:

```sh
flutter build apk --release --dart-define-from-file=config/azure.json
```

The expected output is `build/app/outputs/flutter-apk/app-release.apk`. Direct
Gradle builds can set the package ID with `-PriderApplicationId=...`; the
environment variable works for Flutter's Gradle invocation. The package ID is
applied to all variants in that configured invocation, so leave it unset for
existing scaffold-ID debug builds.

If any required setting is missing or invalid, a release packaging request
stops before tasks execute and names only the missing setting keys. No release
artifact is produced. A successful local build verifies compilation and
signing only; it does not certify store ownership, Azure behavior, or Android
device acceptance.
