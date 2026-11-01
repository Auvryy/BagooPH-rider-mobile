# Android release packaging

Ordinary debug APK builds keep the existing scaffold application ID when no
release ID is configured. Release APK/AAB packaging requires an approved package
ID and a local signing key; the build never falls back to the Android debug key.

## Optional single-architecture defense preview

The current universal debug APK is 249 MB and contains the debug VM snapshot
plus three Android ABIs. To prepare a smaller local preview for a 64-bit ARM
device, build only the `arm64` profile variant:

```sh
flutter build apk --profile --target-platform android-arm64 --dart-define-from-file=config/azure.json
```

The expected output is `build/app/outputs/flutter-apk/app-profile.apk`. Flutter's
profile variant inherits debug signing, and this project uses the scaffold
application ID unless an approved `RIDER_APPLICATION_ID` is supplied. This is a
local preview build, not a distributable release. Confirm the target device ABI
before installation; a successful PC build would not establish Android device
acceptance.

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
