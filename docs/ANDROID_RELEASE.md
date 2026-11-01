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

Arm64-targeted debug and profile APKs were built sequentially from pushed Rider
commit `961d8b8` (`fix/rider-route-privacy-disclosure`) after the parcel photo
access-loss cleanup change. The ignored `.env.rider.json` supplied only
`OPERATIONS_WRITES_VERIFIED=true`; no API override or local-auth define was
present. Gradle used one worker and a 1 GiB heap cap. Both builds completed
with a nonfatal SDK XML version warning.

| Variant | Size | SHA-256 | Verification |
|---|---:|---|---|
| Debug | 176,229,927 bytes | `5050251401b82e6d2e4f2d8e829ed23326be9138e699c983167b1c6bb71b3ce0` | ZIP integrity; package/SDK metadata; ARM64 engine; APK v2 signature |
| Profile | 77,671,976 bytes | `9d7e1041c013f67e9bafd438b5075668a4489f0fdc6721d6bad1ad9ff731ea64` | ZIP integrity; package/SDK metadata; ARM64 engine; APK v2 signature |

Both have package ID `com.example.bagoo_rider_mobile`, version `0.1.0` (code
1), minimum SDK 24, target SDK 36, and one standard Android Debug signer. Both
are debuggable and are not distributable release artifacts. They were not
installed or launched; no phone, ADB, or emulator was used. These PC artifacts
do not establish Android hardware, Azure, or production cross-role acceptance.

The local build file set only `OPERATIONS_WRITES_VERIFIED=true`; it supplied no
API override or local-auth flag. `AppConfig` therefore uses the default deployed
HTTPS API, whose string is present in both compiled APK payloads. Under the
accepted [HDB-05 profile](plans/home-dashboard-branch-plan/HDB-05-EVIDENCE.md),
that flag enables duty and pickup claims only. Parcel, paid delivery, cash,
messages, notifications and handover write gates remain false. This confirms
build configuration, not current service availability or live transaction
acceptance. Use only an approved rider and isolated owned resources for any
future live rehearsal.

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
