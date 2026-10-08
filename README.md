# BagooPH Rider Mobile

Flutter application for BagooPH pickup and delivery couriers. Both assignment
phases belong to the same rider app and courier account role.

## Current account flow

- Real Laravel account login, own-account home and current-device logout.
- Registration with rider details, vehicle, private documents and email verification.
- Grouped registration fields with responsive columns and numbered circular steps.
- User-supplied GooRiders logo for Flutter headers and Android/web launcher icons,
  with bundled Plus Jakarta Sans and the Rider design tokens.
- Android application scaffold, with Linux and web development targets.
- Direct Azure account access on ordinary Android/Linux runs; optional layout frame.
- New applications remain pending server review. No parcel actions exist yet.

Approved accounts now open **Tasks, Trips, Messages and Profile** navigation,
with Settings under Profile. Operational native resources remain unavailable;
the app offers the configured Rider website instead of showing fictional live
queues, history or messages. See [Rider pages](docs/RIDER_PAGES.md).

Everyday builds use real Azure account access. Sample pages are confined to
widget tests and have no app button or route. The
[native API handoff](docs/api/WORKSPACE_HANDOFF.md) records backend prerequisites
for live queues, trips and messaging.

See [working account access](docs/ACCOUNT_ACCESS.md) for setup, controls and limits.

Profile now includes website-aligned contact, password and additional-email
forms prepared for the native app. Native settings integration is prepared and
gated by the server's supported version. Backend main now implements the
[Settings contract](docs/api/SETTINGS_HANDOFF.md); Azure deployment and live
acceptance are still being prepared. See
[account settings](docs/SETTINGS.md) for the exact behavior and remaining live checks.

The existing Bagoo Laravel application remains the backend and source of business
rules. Future API integration must preserve approval, assignment scope, authenticated
custody, buyer-only completion, and separate COD reconciliation. This repository
does not modify the web/backend project.

## Rider plan

Start with the [documentation map](docs/README.md) for rider responsibilities,
the recommended Flutter stack, application architecture, the proposed Laravel
API contract, and acceptance checks.

The [major task map](docs/TASK_TRACKING.md) defines 16 work areas, their screens,
build order, dependencies and completion evidence. The
[detailed backlog](docs/SUBTASK_BACKLOG.md) breaks them into **180 subtasks** and
**63 suggested batches**, with stable IDs, steps, checks, dependencies and effort.
Later prompts can request one card or a batch; full feature cards remain planned.
Always reference the current Bagoo website project's docs and features before
each slice so changes in other
roles stay visible; [sources and synchronization](docs/SOURCES.md) explain where
to check. The map is a plan, not implemented app functionality.

The selected frontend direction is **Stop Mode, Parcel Finder and Doorstep
Guide**. [Their feature plan](docs/FEATURE_DIRECTION.md) defines the desired
screens, acceptance, dependencies and pickup-versus-final-mile dispatch model.
These are selected additions for planning, not implemented starter features;
the detailed catalog and estimate still describe the existing baseline.

The [complete frontend design specification](docs/DESIGN_SPEC.md) now defines
navigation, the counted screen inventory, page-by-page composition, responsive
geometry, visual tokens, maps, theory-based rationale and illustrative layouts.
It covers the current plan plus explicitly optional/conditional/future concepts;
the full inventory remains planned. The account access slice is implemented
locally; the wider operational inventory remains planned.

The working presentation target is **November 21, 2026** in Asia/Manila.
Development and verification should finish by **November 20**. The
[delivery plan](docs/DELIVERY_PLAN.md) records dependencies and scope decisions;
the date does not imply that the proposed features are implemented.

## Requirements

Created with Flutter 3.47.1 and Dart 3.13.1. Use that version or a compatible newer
stable Flutter SDK. Commit `pubspec.lock` to keep resolved dependencies consistent.

Linux development needs Flutter's Linux desktop toolchain. Chrome is used for the
web target. Android builds require the Android SDK and a compatible JDK; the Android
Studio IDE and an emulator are optional when using command-line tools and a real phone.

## Run locally

Ordinary native launches connect directly to the deployed Azure HTTPS API:

```sh
flutter pub get
flutter run -d linux
```

Sign in with your current Rider website credentials. Your account's real server
approval/restriction state decides which pages are available. Passwords are never
bundled or automatically filled. No Home/workspace sample entry is available.

For an authorized connected Android phone:

```sh
flutter run --dart-define-from-file=config/azure.json
```

Select the Android device if Flutter offers multiple targets. For an installable
APK, build the same connected app:

```sh
flutter build apk --debug
```

The APK is `build/app/outputs/flutter-apk/app-debug.apk`. Replacement installation
is needed after rebuilding a phone package, but changing between a sample app
and a live app is no longer part of the workflow. With a connected phone,
`flutter run` installs and launches the app for you.

`config/azure.json` makes the same server choice explicit. The historical
`config/workspace-preview.json` is now a compatibility alias for that live
configuration; old HOME_PREVIEW/WORKSPACE_PREVIEW flags are ignored by app routing
and never clear the API address. Device Preview is disabled by default. Developers
can explicitly enable its layout frame with `--dart-define=DEVICE_PREVIEW=true`;
this still uses real Azure account access on Linux.

Use Linux/Android for deployed account checks. Chrome does not implement the
accepted native secure-session workflow and is not the everyday login target.
Explicit custom/local API configurations remain available for isolated developer
checks; follow [account access](docs/ACCOUNT_ACCESS.md). Never put real credentials
in source, documentation, command-line build defines or logs.

See [Azure account access](docs/AZURE_ACCOUNT_ACCESS.md) for the accepted contract,
secure-session behavior and the precise live-versus-local evidence.

## Project files

See [branding and icon generation](docs/BRANDING.md) for the active logo,
provenance and reproducible launcher resources.

```text
lib/main.dart       App entry point and live login/register routes
lib/app/            Rider theme
lib/core/ui/        Shared Bagoo identity
lib/features/auth/  Login, registration, and shared form presentation
assets/             Bagoo mark, Plus Jakarta Sans font and font license
test/               Account behavior, transport and responsive layout checks
android/            Android runner
linux/              Linux preview runner
web/                Web preview runner
pubspec.yaml        App metadata and dependencies
```

## Checks

```sh
flutter analyze
flutter test
flutter build linux --debug
flutter build web
```

The Android application identifier and Flutter launcher icons are scaffold defaults
to finalize before a mobile release. Begin with current website/API agreement
(B01-A), then the remaining prerequisite conventions and Flutter foundation. Authentication
and approval holding follow against accepted native endpoints. Select the later
slice from the detailed backlog instead of treating the whole plan as one branch.
