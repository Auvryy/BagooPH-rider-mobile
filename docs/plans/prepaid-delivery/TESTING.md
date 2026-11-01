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
Linux display are required. Pin the accepted backend source revision:

```sh
node tool/parcel_local_api/run.mjs ../bagoo prepaid 9e58312d130809eb8cd878189b729f1f702291d8
```

The native acceptance now requires a version-two completed order, paid Wallet
status, the exact original recipient, authenticated retained proof bytes matching
the original image hash, one original replay and zero COD accounts. It passed
once against the pinned backend revision. Use `xvfb-run -a` before the command
when available to keep the Linux test window off the active desktop; otherwise
run it from an existing Linux desktop session. Never create a fake COD record
to satisfy the check.

## Separate controlled acceptance

Follow the [owner checklist](../../api/PREPAID_DELIVERY_NEEDS.md). Confirm the
deployment, migrations and fresh operations-v1 session, then use designated
isolated COD and paid Wallet assignments through their owning workflows.
Verify one intended outcome/receipt, original replay, retained private proof and
foreign/reassigned access. Buyer completion and cash remittance remain separate.

Physical Android scanning, permissions, camera/picker recovery and interrupted
upload are deferred until a phone is available. PC layouts and native Linux
compatibility cannot establish those results.
