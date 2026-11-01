# BagooPH Rider Mobile

Flutter application for BagooPH couriers handling seller pickup and assigned
final-mile delivery. Rider is a courier-role client; Buyer, Seller, logistics
hub and Admin workflows belong to their own applications. The backend remains
authoritative for approval, assignment, parcel custody, order state, COD and
earnings.

## Current Rider app

The repository contains a working native client, not only the original account
starter. It includes:

- Real Azure account access, email-verified registration, approval/restriction
  holding, secure session restoration and logout.
- Home and task queues, assigned pickup/departure actions, Stop Mode and
  buyer-provided stop instructions when the task supplies them.
- Android waybill camera integration, recipient and private photo evidence,
  exact COD entry, failed-delivery reporting and protected recovery of
  uncertain submissions.
- Retained Trips with an in-app private proof viewer, plus Messages,
  Notifications, Cash & Remittance, Company and handover issue pages.
- Rider Profile and Settings, with some account/security actions handed off to
  fixed first-party website pages.

These are client capabilities; they do not prove that every action is enabled or
accepted on Azure. Operational write gates default to off and require their own
deployment and cross-role evidence. The current client state and outstanding
gates are summarized in [verification and readiness](docs/VERIFICATION_AND_READINESS.md),
with flow-specific details in the [workflow rehearsal](docs/plans/rider-workflow-recovery/REHEARSAL.md)
and [delivery verification](docs/plans/rider-orders-delivery-trips/VERIFICATION.md).

## Rider app and phone website

The phone-responsive Courier website also supports waybill scanning and proof
photo uploads, so those should not be presented as unavailable on the web. The
clearest extra Rider feature is **Parcel Finder**: a rider can attach a
session-only personal location label to an owned parcel in Stop Mode. It does
not assign, scan or change custody. Other differences are the Android camera
lifecycle integration, encrypted account/API-scoped recovery for uncertain
commands and original proof, and the private proof viewer in Trips. See the
[source-backed comparison](docs/plans/rider-workflow-recovery/REHEARSAL.md).

The Rider and Courier website remain two presentations of the courier role.
Pending cash-offer review and cancellation, and selected account/security flows,
still open the first-party website.

## Map and location behavior

Android renders the bundled Leaflet map in Android System WebView. Linux Device
Preview uses a FlutterMap fallback. The map displays a saved stop or a clearly
labelled sample illustration; its sample line is not certified road geometry,
an assignment or a delivery claim. The default road-routing provider is
unavailable, so the app has no in-app road route, GPS-follow or rerouting
session. When a rider explicitly opens External directions, Google Maps receives
the saved stop destination. OpenStreetMap tile requests reveal the displayed
area through tile coordinates and source IP. See the
[street-map plan](docs/plans/rider-street-map/README.md) for renderer and
disclosure details.

## Project plan and design

The [documentation map](docs/README.md) links the architecture, courier flow,
API handoffs and selected implementation plans. The
[major task map](docs/TASK_TRACKING.md) groups work into 16 areas; the
[detailed backlog](docs/SUBTASK_BACKLOG.md) contains 180 cards and 63 suggested
batches. These remain the full project plan, not a claim that every card is
implemented. Check each plan and the readiness record for its actual state.

Stop Mode and session-only Parcel Finder have client implementations. The
current Doorstep Guide shows buyer-provided stop instructions when present;
richer authorized collection and entrance fields remain planned. Their behavior
and remaining acceptance are recorded in the
[feature direction](docs/FEATURE_DIRECTION.md),
[Parcel Finder verification](docs/plans/rider-parcel-finder/VERIFICATION.md)
and [workflow rehearsal](docs/plans/rider-workflow-recovery/REHEARSAL.md).
Visual tokens and interaction guidance are in the
[Rider design system](docs/DESIGN_SYSTEM.md).

The working presentation target is **November 21, 2026** in Asia/Manila;
November 20 is the latest development deadline. The
[delivery plan](docs/DELIVERY_PLAN.md) records scope and capacity constraints.

## Local development

Use Flutter 3.47.1 / Dart 3.13.1 or a compatible newer stable SDK. Sample
repositories and preview fixtures are for automated tests; ordinary app
launches use real account access. There is no Demo login or Preview Rider route.

For a phone-sized preview on Linux, run from this repository root:

```sh
flutter run -d linux --debug --dart-define=DEVICE_PREVIEW=true --dart-define-from-file=.env.rider.json
```

The ignored `.env.rider.json` file preserves local Rider configuration. If it is
absent, omit only `--dart-define-from-file=.env.rider.json`; do not add sample
login or enable operational write gates. For ordinary Linux use, run
`flutter run -d linux --debug`; it connects to the configured Azure account
service. Chrome is a layout target, not an accepted native secure-session test
target.

When an authorized Android test device is available, Flutter can target its
device ID with the same local Rider configuration. Android camera, picker,
permission and process-lifecycle acceptance must be recorded on the physical
device; Linux preview does not establish those results. For account setup and
live-check limits, see [account access](docs/ACCOUNT_ACCESS.md) and
[Azure acceptance](docs/AZURE_ACCOUNT_ACCESS.md).

## Android release

The debug/profile APK uses a scaffold application ID and debug signing. A
production release requires an approved Rider package ID and local signing
configuration; neither is present in the current PC setup. Release packaging is
fail-closed until those inputs are supplied. See
[Android release packaging](docs/ANDROID_RELEASE.md). A locally built or signed
APK alone does not establish device, deployment or cross-role acceptance.

## Verification

The full PC regression passed **696 tests with 7 expected skips and zero
failures** at historical checkout `38e25cf`, with one Flutter test worker and
no phone, ADB, emulator or visible app. Since then, focused PC accessibility
suites passed **71 core-flow**, **145 extended-page** and **23 motion/high-
contrast** tests; the updated scanner widget file passed **3/3**, including two
new responsive cases. `flutter analyze --no-pub` is also clean after those test
changes. No runtime Dart code changed. Exact commands, revisions, skip reasons,
APK evidence and remaining gates are in
[verification and readiness](docs/VERIFICATION_AND_READINESS.md).

Run the serial checks individually to keep resource use bounded:

```sh
flutter analyze --no-pub
flutter test --no-pub --concurrency=1 --reporter=compact test
```

These PC checks do not replace deployed Azure/cross-role acceptance or physical
Android camera, photo-picker and lifecycle review. Current operational writes,
release signing and those acceptance gates are tracked in the linked readiness
record.

## Project files

```text
lib/main.dart                    App entry point and account routes
lib/features/auth/               Login, registration and session state
lib/features/home/               Home, task queues and Stop Mode
lib/features/parcels/            Waybill scanning and delivery outcomes
lib/features/parcel_finder/      Session-only personal parcel labels
lib/features/navigation/          Maps, saved stops and external directions
lib/features/trips/               Retained history and private proof viewing
lib/features/messages/             Assignment-bound rider messages
lib/features/notifications/       Rider notification inbox
lib/features/cash/                Cash and remittance presentation
lib/features/handover/             Handover issue reporting/recovery
lib/features/settings/             Rider profile and account settings
docs/plans/                        Feature plans and acceptance evidence
test/                               Controller, transport and widget checks
assets/                             Branding, typeface and bundled map files
android/, linux/, web/              Platform runners
pubspec.yaml                        App metadata and dependencies
```
