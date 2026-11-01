# Android release packaging

Ordinary debug APK builds keep the existing scaffold application ID when no
release ID is configured. Release APK/AAB packaging requires an approved package
ID and a local signing key; the build never falls back to the Android debug key.
At Rider revision `e0aa20e`, a PC release-build request stopped before artifact
generation because the approved ID and all local signing settings were absent.
This verifies the fail-closed guard; it is not release-build acceptance.

## Optional arm64-targeted defense preview

The universal debug APK is 249 MB and contains the debug VM snapshot and
Flutter libraries for three Android ABIs. For a smaller profile-mode preview
for a 64-bit ARM device, target the Flutter app to `arm64`:

```sh
flutter build apk --profile --target-platform android-arm64 --dart-define-from-file=config/azure.json
```

The expected output is `build/app/outputs/flutter-apk/app-profile.apk`. The
profile variant uses debug signing, and this project uses the scaffold
application ID unless an approved `RIDER_APPLICATION_ID` is supplied. The
current PC build at Rider code revision `9d7e8cf` produced a 77,606,440-byte
APK with SHA-256
`28be6a6645ce7549ee0ad94b4c36491c75cd3fdecc601d7cfabeae689c622d84`. The
merged manifest reports package `com.example.bagoo_rider_mobile`, min SDK 24,
target SDK 36, version code 1 and version name `0.1.0`. Flutter's app library
targets arm64; some plugin libraries for other ABIs remain in the APK. The APK
archive passed integrity verification. `apksigner verify` confirmed the APK v2
signature with one signer. This is a local profile preview using the scaffold
application ID and debug signing, not a distributable release. It was not
installed and does not establish Android device acceptance.

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
