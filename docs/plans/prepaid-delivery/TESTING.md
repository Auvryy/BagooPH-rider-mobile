# Testing paid Wallet delivery

Run from the Rider repository root. The PC phone frame retains normal Azure
login; without accepted write gates it permits browsing rather than delivery:

```sh
flutter run -d linux --debug --dart-define=DEVICE_PREVIEW=true --dart-define-from-file=.env.geoapify.json
```

Select an owned task to inspect the returned payment instructions. A Wallet task
becomes eligible only at the buyer stop with paid-source authorization. Missing
payment information and unsupported sources must remain unavailable. Do not
enable write gates merely to demonstrate the interface.

## Local checks without Azure or a phone

```sh
flutter analyze --no-pub
flutter test --no-pub test/prepaid_delivery_test.dart test/task_payment_instruction_test.dart test/parcel_workflow_test.dart test/parcel_outcome_pages_test.dart test/trips_pages_test.dart --dart-define=RIDER_WORK_RENDER=true
flutter test --no-pub
```

Tests cover cash omission, exact COD, payment changes without version changes,
original proof/UUID recovery, default-false activation and 200% text layouts.
Opt-in renders are synthetic and remain under ignored `build/` directories.

The [isolated native runner](../../../tool/parcel_local_api/README.md) uses
committed backend source, normal domain workflows, ephemeral accounts, SQLite
`:memory:` and real native Dio/protected storage. A native secret service and
Linux display are required; use a virtual display to keep windows off the active
desktop:

```sh
xvfb-run -a node tool/parcel_local_api/run.mjs ../bagoo prepaid
```

The current diagnostic checks paid handoff and original replay, then reproduces
the reviewed backend's retained Wallet proof/recipient gaps. Its passing exit
does **not** accept those gaps. After the owner fixes them, update its assertions
to require authenticated original proof bytes and the original recipient, then
rerun against that fixed revision. Never create a fake COD record to satisfy it.

## Separate controlled acceptance

Follow the [owner checklist](../../api/PREPAID_DELIVERY_NEEDS.md). Confirm the
deployment, migrations and fresh operations-v1 session, then use designated
isolated COD and paid Wallet assignments through their owning workflows.
Verify one intended outcome/receipt, original replay, retained private proof and
foreign/reassigned access. Buyer completion and cash remittance remain separate.

Physical Android scanning, permissions, camera/picker recovery and interrupted
upload are deferred until a phone is available. PC layouts and native Linux
compatibility cannot establish those results.
