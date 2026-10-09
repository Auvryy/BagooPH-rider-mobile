# Efficient stack for the rider app

## Recommendation

Use Flutter for the native client and a versioned JSON API inside the existing
Laravel monolith. Keep the existing PostgreSQL-backed business data and current
hosting arrangement. There is no need for a second backend, Firebase database,
GraphQL gateway, microservices, or a new cloud account for this scope.

The efficiency comes from reusing backend policies/services, adding packages
only as features need them, and testing UI on Linux while verifying hardware
on an Android phone. These are design choices, not measured RAM/battery savings.

## Installed versus proposed

| Tool | Status | Purpose and selection reason |
|---|---|---|
| Flutter 3.47.1 / Dart 3.13.1 | Starter SDK | Current creation baseline; agree on one compatible SDK before upgrades |
| Material widgets, Cupertino icons | Installed | Flutter UI and established icon set |
| `device_preview` | Installed, debug Linux/web only | Phone layout, orientation, and text-scale preview without an Android emulator |
| `flutter_test`, `flutter_lints` | Installed development dependencies | Appropriate automated checks as features are added |
| `flutter_launcher_icons` 0.14.4 | Installed development dependency | Reproduce legacy/adaptive Android and web launcher resources from the supplied Rider logo; MIT licence |
| `file_selector` 1.1.0 | Installed for registration | Real local document selection and private API submission |
| `file_selector_platform_interface` 2.7.0 | Installed development dependency | Replace the picker in behavior checks without opening native dialogs |
| `flutter_riverpod` | Installed for account state | Dependency injection and asynchronous screen/controller state in one tool |
| `dio` | Installed for account transport | Shared request configuration, interceptors, cancellation, timeouts, multipart uploads |
| `go_router` | Proposed with auth navigation | Explicit holding/auth/task routes and guarded deep links |
| `flutter_secure_storage` | Installed for native account sessions | Small per-device token storage; requires native platform setup |
| `mobile_scanner` | Proposed with custody scan feature | Device camera barcode/QR decoding; server still validates the submitted waybill |
| `image_picker` | Proposed with delivery proof | Capture/select genuine images; handle Android lost-data recovery |
| `url_launcher` 6.3.3 | Installed for Rider website actions | Fixed allowlisted HTTPS destinations in the system browser; native bearer never enters a URL |
| `package_info_plus` 10.2.2 | Installed for About Rider | Actual app version/build information; no invented release/version label |
| `integration_test` | Installed development SDK dependency | Opt-in native account checks and Linux-rendered workspace preview checks |
| `intl` | Proposed when dates/money appear | Locale display; no floating-point money authority or guessed timezone |
| Bundled Plus Jakarta Sans | Implemented fallback font asset | Variable font with bundled SIL Open Font License; no runtime font download |

Package versions are deliberately not presented as installed until they enter
`pubspec.yaml` and resolve in `pubspec.lock`. At each implementation task check
current maintenance, Flutter/Dart compatibility, minimum Android SDK, native
configuration, transitive size, and license. Commit the resolved lockfile.
Do not upgrade all packages merely because a newer release exists.

[Account access](ACCOUNT_ACCESS.md) records the bundled assets, document flow,
Dio transport, Riverpod state and secure-store checks. The account gate uses
Material named routes; broader guarded operational routing remains future work.

The package purposes above are supported by their primary docs:
[Riverpod](https://pub.dev/packages/flutter_riverpod),
[Dio](https://pub.dev/packages/dio),
[go_router](https://pub.dev/packages/go_router), and
[url_launcher](https://pub.dev/packages/url_launcher).
The app-specific choice of these packages is this plan's recommendation.

## Platform constraints

| Capability | Linux / Device Preview | Physical Android |
|---|---|---|
| Screen layout, empty/error/loading states | Useful daily development target | Final touch/text/keyboard review |
| Camera waybill scanner | `mobile_scanner` does not support Linux; explicit debug input/fake adapter only | Real scanning, permission denial, lifecycle, low light |
| Proof camera | Desktop `image_picker` has no default camera UI; file input can support development | Real camera/gallery, cancellation and process recreation |
| Token store | Needs `libsecret` and an available Secret Service/keyring on Hyprland | Native storage, backup/restore and expiry verification |
| Maps/directions/calls | Layout and fallback checks; desktop handlers may differ | Installed navigation/dialer behavior and safe failures |
| Network/app lifecycle | Transport/controller checks | Background, app kill, resume, flaky connectivity and upload retries |

Linux preview is a Flutter desktop app drawn inside a phone frame, not an Android
emulator. It still consumes resources and cannot certify native behavior.
Use a clearly labelled fixture configuration when backend or plugins are absent;
never let that configuration call production or return operational success.

These limitations come from [mobile_scanner's platform matrix](https://pub.dev/packages/mobile_scanner),
[image_picker's desktop and Android guidance](https://pub.dev/packages/image_picker),
and [secure storage's Linux setup](https://pub.dev/packages/flutter_secure_storage).
The scanner offers bundled/unbundled Android decoding options: decide after
measuring APK size and first-use behavior. Prefer a reliable first scan without
an unexpected network model download for the demonstration.

## Arch Linux workflow

Keep Linux desktop preview for normal editing and hot reload. Use Flutter DevTools
when profiling a concrete bottleneck. For native checks, install only the Android
command-line SDK/platform/build tools and compatible JDK needed by the agreed
Flutter/Gradle versions, accept licenses, and connect a phone with USB debugging.
Android Studio's IDE and an emulator are optional; the SDK is required.

```sh
flutter doctor -v
flutter pub get
flutter run -d linux
flutter devices
flutter run -d <android-device-id>
```

The placeholder device ID comes from `flutter devices`. Do not install tooling
or change system packages just to write docs. Follow the current
[Flutter Android setup](https://docs.flutter.dev/platform-integration/android/setup)
and [Android SDK command-line tools](https://developer.android.com/tools/sdkmanager)
when that setup task begins. The current Android docs deprecate `sdkmanager`
in favor of the Android CLI's `android sdk` command; follow tooling compatible
with the selected Flutter SDK rather than copying an old installation script.
Build a signed release only after package identity,
permissions, HTTPS environment, and signing storage are agreed.

## Backend and hosting

The reviewed backend declares Laravel `^13.17`, Sanctum `^4.0`, and PHP `^8.3`.
Its architecture uses Laravel/Inertia with React for web UI and PostgreSQL;
Docker Compose includes PostgreSQL 16. Mobile consumes JSON, not Inertia pages.
Use one set of services with separate web and API presentation adapters.

Use the existing Azure/Cloudflare deployment if that is the operator's current
arrangement. Its live configuration was not inspected in this docs task. Before
mobile release verify origin TLS, API routing, private storage, trusted proxies,
body limits, and cache/challenge behavior as described in the integration plan.

Sanctum personal access tokens are the proposed native auth method. Explicit
expiration, revocation, account checks, and token abilities must be implemented;
the package dependency alone provides none of this app's flow.
[Sanctum documentation](https://laravel.com/framework/docs/13.x/sanctum)
distinguishes mobile API tokens from first-party browser session authentication.

## Add only when justified

Start with hand-written immutable DTOs and a small number of repositories.
Add `json_serializable`/`build_runner` when repeated DTO conversion becomes
costly and a stable schema exists. Consider Freezed only when model unions or
copy/equality work justify its generation overhead. Do not combine Riverpod,
Bloc, GetX, and another global service locator.

No local database is required for the first online version. Keep private queues
in memory and make interrupted actions recoverable via server idempotency.
Full offline drafts, maps, push services, sockets, and client generation each
need a separate need, maintenance estimate, and privacy decision.
