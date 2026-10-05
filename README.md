# BagooPH Rider Mobile

Flutter application for BagooPH pickup and delivery couriers. Both assignment
phases belong to the same rider app and courier account role.

## Starter scope

- Minimal BagooPH Rider welcome screen.
- Android application scaffold, with Linux and web development targets.
- Device Preview phone frames and controls on debug Linux/web runs.
- No authentication, API connection, parcel actions, or sample operational data yet.

The existing Bagoo Laravel application remains the backend and source of business
rules. Future API integration must preserve approval, assignment scope, authenticated
custody, buyer-only completion, and separate COD reconciliation. This repository
does not modify the web/backend project.

## Requirements

Created with Flutter 3.47.1 and Dart 3.13.1. Use that version or a compatible newer
stable Flutter SDK. Commit `pubspec.lock` to keep resolved dependencies consistent.

Linux development needs Flutter's Linux desktop toolchain. Chrome is used for the
web target. Android builds require the Android SDK and a compatible JDK; the Android
Studio IDE and an emulator are optional when using command-line tools and a real phone.

## Run locally

From this repository:

```sh
flutter pub get
flutter run -d linux
```

Use Device Preview's controls to choose a phone, orientation, and text scale.
Press `r` in the terminal to hot reload and `q` to quit.

For a browser preview:

```sh
flutter run -d chrome
```

To see the normal Linux window without the phone frame:

```sh
flutter run -d linux --dart-define=DEVICE_PREVIEW=false
```

Device Preview is disabled on physical Android devices and in release builds. It
previews layouts; camera scanning, permissions, and device behavior still need
verification on a real phone.

## Project files

```text
lib/main.dart       App entry point, starter screen, and preview setup
android/            Android runner
linux/              Linux preview runner
web/                Web preview runner
pubspec.yaml        App metadata and dependencies
```

## Checks

```sh
flutter analyze
flutter build linux --debug
flutter build web
```

The Android application identifier and Flutter launcher icons are scaffold defaults
to finalize before a mobile release. The next feature is rider authentication and
approval holding against an agreed Laravel API contract.
