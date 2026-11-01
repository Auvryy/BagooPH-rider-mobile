# Implementation and verification record

October 18, 2026 · branch `feat/rider-orders-delivery-trips` · base `3c68857`.
This records implemented client behavior and its evidence. Controlled Azure and
physical Android acceptance remain unfinished parts of the selected objective.

## November 1 branch regression recheck

At Rider commit `866342f` on `fix/rider-workflow-recovery`, the serial Flutter
unit/widget/transport suite passed **692 tests**, with six skips, and exited 0.
`flutter analyze --no-pub` and targeted analysis of
`integration_test/parcel_local_api_test.dart` reported no issues. Commands:

```sh
flutter test --no-pub --concurrency=1 --reporter=compact test
flutter analyze --no-pub
dart analyze integration_test/parcel_local_api_test.dart
flutter build apk --debug --no-pub --dart-define-from-file=.env.rider.json
rider_android_sdk="$(sed -n 's/^sdk.dir=//p' android/local.properties)"
"$rider_android_sdk/build-tools/36.0.0/aapt" dump badging build/app/outputs/flutter-apk/app-debug.apk
sha256sum build/app/outputs/flutter-apk/app-debug.apk
```

The debug APK built at local HEAD `55535b7` is
`build/app/outputs/flutter-apk/app-debug.apk`, SHA-256
`926228ca059761db60c5a528e594d7f982eddd1f1452219e1e273d12d740fefc`. Its
manifest reports `com.example.bagoo_rider_mobile`, version `0.1.0+1`, minimum
SDK 24 and target SDK 36. The existing local profile uses the deployed API and
website defaults with local authentication disabled; duty/claim remains enabled,
while parcel, Wallet, cash, messages, notifications and handover write gates
remain disabled. This is a debug artifact, not a signed production release; it
was not installed or exercised on a phone.

This recheck did not run native integration, Azure, physical Android or deployed
cross-role acceptance. Their separate evidence and gates below remain unchanged.

A separate focused headless PC check passed **1/1** against Bagoo commit
`9e58312`. It ran with the exact pinned source:

```sh
node tool/parcel_local_api/run.mjs ../bagoo parcel-headless 9e58312d130809eb8cd878189b729f1f702291d8
```

The test used the isolated SQLite fixture, normal request spacing and an in-memory
secure-storage adapter. It verified final-mile departure, a recorded failed
attempt, courier-to-hub custody receipt, removal from active delivery work, and
hub-approved retry/reassignment with retained Trips attempt proof bytes and a
404 denial to another rider. It created no cash account or public proof, opened
no app window and used no phone. This supplements the current branch checks; it
does not replace full native, Android or recovery/RTS acceptance.

## November 1 headless COD acceptance

The expanded windowless check passed **1/1** from Rider branch
`test/rider-headless-cod-delivery`, against the read-only Bagoo source pinned to
`9e58312d130809eb8cd878189b729f1f702291d8`:

```sh
node tool/parcel_local_api/run.mjs ../bagoo parcel-headless 9e58312d130809eb8cd878189b729f1f702291d8
```

Using the real Rider repository over loopback HTTP, the synthetic run drove
assigned destination-hub departure and exact recipient/COD evidence. A simulated
lost committed response recovered from the original journal and private proof;
replaying the original idempotency key, body and image returned a replay and left
one delivery and one cash event. The private cash evidence retained the recipient,
relationship, exact tender/change and proof hash. Trips returned the same private
proof bytes, and public proof storage stayed empty. On this pinned backend,
verified recipient handoff marks the COD payment paid and the order completed
automatically; the rider still holds one unreconciled cash balance. A separate
buyer confirmation call is not required for this revision. The failed-attempt,
destination-hub return, retry/reassignment, retained attempt proof and foreign
rider denial checks also passed in the same run.

This is local client-to-kernel evidence only. It opened no app window and used no
connected phone, Azure endpoint, live account or live write gate. It does not
establish that the pinned Bagoo branch is deployed. The Rider native integration
expectations were aligned with this source behavior and statically analyzed; the
native windowed suite was not run in this PC-only slice.

## Passed local checks

| Check | Result |
|---|---|
| Full Flutter unit/widget suite | **428 passed, four expected skips** |
| Selected parcel/Trips tests with real font/image rendering | **71 passed** |
| Flutter analysis | No issues |
| Ordinary Linux debug build | Passed, real Azure entrypoint |
| Ordinary Android debug APK | Passed, real Azure entrypoint |
| Native Linux client → isolated Laravel kernel | One comprehensive scenario passed |
| New documentation links and Git diff checks | Passed |

The full-suite skips are three opt-in historical redesign captures and the
alternate-API configuration case. New parcel and Trips renders ran separately
with the bundled font, actual image decoding and reduced motion. Review covered
320px/840px outcome forms at 200% text and 320px/375px/900px retained-history
layouts. The decoder check rejects the old invalid synthetic PNG checksum.

Commands used:

```sh
flutter analyze --no-pub
flutter test --no-pub --reporter expanded
flutter build linux --debug --no-pub --dart-define-from-file=.env.geoapify.json
flutter build apk --debug --no-pub --dart-define-from-file=.env.geoapify.json
node tool/parcel_local_api/run.mjs ../bagoo
```

Native execution used a virtual display and the normal Linux secure-storage
plugin. The final ordinary Linux build restored the normal app entrypoint after
integration testing. No ordinary build contains a sample login, fabricated scan
route or local-kernel endpoint.

## Real native/client-to-kernel observations

The runner froze committed backend
`c12747bb1dd0046bd389b54b336122117fc21dbc` without changing the reference checkout.
The selected Rider API/custody services and migrations match reviewed `14b589f`.
Database state was SQLite `:memory:`; actors, parcels and images were synthetic.
Runtime files were removed after the run. No Azure domain command was sent.

- Fresh version-1 login and real Home parcel/Trips capabilities decoded.
- Off-duty/on-duty writes and original-key claim replay preserved one assignment.
  A claim did not collect the parcel.
- An interrupted collection request remained unknown, then retried its original
  intent. Owned work remained usable off duty. Only the owning hub recorded intake.
- Hub-assigned departure led to the buyer stop. COD delivery preserved the original
  encrypted image across repository recreation and recovered a lost committed
  response. Replaying its multipart intent left one outcome and one collection.
- Exact received/change and the cash balance agreed. In this earlier native run,
  buyer receipt and COD reconciliation remained separate; the buyer's own
  workflow completed the order without reconciling rider cash.
- Failure used the returned reason policy, required proof/notes/place and one
  attempt. Custody stayed with the courier until the destination hub received it.
- Retained Trips decoded both phases, original recipient/cash, server search,
  phase/payment filters, inclusive Manila dates and paginated ordering.
- Real private PNG bytes and privacy headers survived authenticated downloads.
  After authorized hub retry/reassignment, the original rider retained their own
  attempt/proof. The next rider could not read that original assignment or image.
- Replacing accepted proof with a different genuine PNG returned `EVIDENCE_CHANGED`.

The bridge uses Node's multipart parser and the unchanged Laravel kernel,
middleware, validators and domain services. It does not test a deployed PHP/proxy
upload stack. Web asset tags are omitted by Laravel's standard test helper; owning
actions still execute their real authorization and transitions. Camera capture is
not substituted into ordinary app code by these tests.

## Remaining live and device acceptance

- [ ] Operator confirms the actual Azure deployment and required migrations.
- [ ] Fresh approved session, real queues/detail, retained Trips and private proof
  are verified on that deployment with the authorized acceptance account.
- [ ] Operator designates sequential isolated pickup, COD and failure resources;
  original-key results agree with the owning hub/buyer/cash observations.
- [ ] Android actual-waybill scan, permission denial/cancel, proof capture and
  interrupted-picker recovery pass on a physical phone.

The GET-only native saved-session probe found **no valid saved authorized session**
and skipped its Azure acceptance check. Its receipt records `reads_verified: false`;
it did not sign in, replace/revoke the scoped session or send domain writes.
Flutter currently detects no Android target. These are missing acceptance inputs,
not evidence that Azure writes or phone behavior passed.

`PARCEL_WRITES_VERIFIED` remains default-false. The existing HDB-05 duty/claim gate
is independent. No additional map key is needed. See the
[operator/API checklist](../../api/ORDER_DELIVERY_TRIPS_NEEDS.md) and
[testing procedure](TESTING.md); local success does not activate parcel writes.
