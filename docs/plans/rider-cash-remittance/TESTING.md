# Testing Cash & Remittance

From the Rider repository root, open the normal Azure app in a PC phone frame:

```sh
flutter run -d linux --debug --dart-define=DEVICE_PREVIEW=true --dart-define-from-file=.env.geoapify.json
```

Open Profile → Cash & Remittance. A fresh operations-v1 session and actual cash
capability are required. Read real retained cash journals and their all-owned
summary, search tracking references and open a journal's original history. Cash
information is not sample data; an empty list or unavailable capability remains
an honest state. Ordinary builds keep remittance offers disabled until accepted.

## Local verification

Contract/controller/widget checks use synthetic responses to exercise exact
amounts, signed history, filtering/pagination, permitted recipients, source
versions, uncertain results, original recovery and account/lifecycle privacy.
Review small/wide layouts with 200% text, keyboard-safe input and ordinary
scrolling. Opt-in synthetic renders remain in ignored `build/` directories.

```sh
flutter analyze --no-pub
flutter test --no-pub
```

The pending-offer website handoff has a focused headless regression in the cash
page suite:

```sh
flutter test --no-pub --concurrency=1 test/cash_pages_test.dart --reporter=expanded
```

The selected [native runner](../../../tool/parcel_local_api/README.md) exercises
the actual Laravel kernel from an immutable committed snapshot. It creates two
synthetic COD deliveries through their owning workflows and tests real native
cash reads/offers, original interrupted-request recovery/replay, independent
owning hub HTTP receipts, a shortage, journal parity and denied foreign access.

```sh
xvfb-run -a node tool/parcel_local_api/run.mjs ../bagoo cash 9e58312d130809eb8cd878189b729f1f702291d8
```

A virtual display keeps the native test off the active desktop. The runner
pins the current reviewed Wallet/handover source branch. It requires the
existing Composer development dependencies, PHP SQLite, Node and
Flutter/Linux toolchain with native secure storage. It restricts all state to
SQLite `:memory:` and isolated files; the runtime is removed on exit. It cannot
target Azure and does not read the ordinary rider's saved login or map key.
The November 1 PC run passed **1/1** on Bagoo source `9e58312d130809eb8cd878189b729f1f702291d8`; its native Linux client ran under Xvfb, with the fixture container capped at 768 MB and the build limited to one worker. The rider's fully receipted COD parcel released **₱25.00** in delivery earnings; the short-paid parcel retained **₱25.00** pending. `dart analyze integration_test/cash_local_api_test.dart` reported no issues.

## Separate operating acceptance

Follow the [API checklist](../../api/CASH_REMITTANCE_NEEDS.md). Confirm deployed
revision/migrations and fresh abilities, then inspect a designated isolated cash
responsibility. Deliberately offer a permitted amount, verify held/remitted stay
unchanged, have the designated hub actor count and receive it independently,
and compare native/website journal facts. Reconcile a saved original request
before retrying. A synthetic UI response is not this cross-role acceptance.

Physical Android keyboard/Back, background/resume, secure-storage recovery and
interrupted-network checks follow when hardware is available. No phone or live
write acceptance is inferred from a debug APK, Linux layout or local kernel.
