# Android release packaging

Ordinary debug APK builds keep the existing scaffold application ID when no
release ID is configured. Release APK/AAB packaging requires an approved package
ID and a local signing key; the build never falls back to the Android debug key.
At Rider revision `e0aa20e`, a PC release-build request stopped before artifact
generation because the approved ID and all local signing settings were absent.
This verifies the fail-closed guard; it is not release-build acceptance.
The November 2 configuration check found `RIDER_APPLICATION_ID` unset and
`android/key.properties` absent. No release APK was produced in this follow-up.

## Current PC builds — November 2, 2026

Fresh arm64-targeted debug and profile APKs were built from pushed Rider branch
head `94d2aaf` (runtime code `30412ed`) with the ignored local
`.env.rider.json` build configuration. Both use the scaffold application ID
`com.example.bagoo_rider_mobile` and the standard Android Debug signing
certificate. Archive integrity, manifest metadata, arm64 contents, and APK v2
signatures passed PC checks. Neither APK was installed or launched; these builds
do not establish physical Android, Azure, or cross-role acceptance.
Gradle emitted a nonfatal warning that the installed Android tools understand
SDK XML through version 3 while the SDK metadata uses version 4; both builds
completed successfully.

## Current arm64 debug review APK

At Rider branch head `94d2aaf` (runtime `30412ed`), this PC-only build produced
the current arm64-targeted debug APK:

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

## Current arm64 profile defense preview

At Rider branch head `94d2aaf` (runtime `30412ed`), this PC-only profile build
produced the current arm64-targeted preview:

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
