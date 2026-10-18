# Testing pickup, delivery and Trips

Run commands from the Rider Mobile repository root. The ordinary app connects
to Azure. Sample responses and loopback fixtures run only in explicit tests.

## Review the app on a Linux PC

```sh
flutter run -d linux --debug --dart-define=DEVICE_PREVIEW=true --dart-define-from-file=.env.geoapify.json
```

Sign in privately with an approved account. Refresh Home, review Available
pickups/My pickups/Assigned delivery, and open Trips. Trips searches tracking or
order numbers and filters retained assignments by phase, payment and inclusive
Manila assignment dates. Non-COD is a history filter; native successful delivery
currently supports COD only. Open a record to refresh its original assignment
and any advertised private proof. Changing filters cannot reuse older results.

Linux supports real account reads, file selection and the existing labelled
manual route origin. It cannot establish Android camera, permission or picker
recovery acceptance. Normal scrolling is used for forms and recorded history.

## Verify locally without Azure writes

```sh
flutter analyze
flutter test
```

The [isolated native runner](../../../tool/parcel_local_api/README.md) exercises
real HTTP requests and the Laravel kernel, with SQLite `:memory:` and synthetic
orders. It needs the reviewed backend checkout and its installed development
dependencies, but no live credentials or map key:

```sh
node tool/parcel_local_api/run.mjs ../bagoo
```

Use a virtual Linux display if the desktop must stay undisturbed. The runner's
owning hub/buyer actions are test-only controls, outside the ordinary app and
API. They do not establish actual physical possession or deployed acceptance.

The opt-in `integration_test/parcel_session_read_test.dart` can reuse the
already-authorized Linux session for GET-only Azure reads, with the expected
account supplied through runtime `BAGOO_EXPECTED_RIDER_ID` and
`--dart-define=LIVE_PARCEL_SESSION_READ_CHECK=true`. It keeps the scoped session
intact and writes a private sanitized receipt under ignored build output.
A missing or different saved session skips the check; it is not Azure acceptance.
It neither signs in automatically nor sends duty, claim or parcel commands.

## Controlled Azure and Android acceptance

Keep `PARCEL_WRITES_VERIFIED` disabled until the operator confirms the deployed
revision/migrations, fresh version-1 account capabilities and designated isolated
parcels in the [API checklist](../../api/ORDER_DELIVERY_TRIPS_NEEDS.md).
The current local checks do not authorize enabling that switch. An approved
controlled test profile must still complete the following acceptance checks.

1. Prepare one eligible pickup with no conflicting final-mile work. Go on duty,
   claim once and verify that claim creates an assignment without collection.
   Review stale/duplicate/denied responses using the original saved intent.
2. Scan the actual software-test waybill on Android. Wrong scans and cancellation
   must leave custody unchanged. Review and confirm collection, then verify that
   the next stop is the origin hub. Going off duty preserves owned work.
3. Have the owning hub record receipt through its own workflow. Only then prepare
   subsequent work. Active final-mile work blocks new pickup claims; an off-duty
   rider is unavailable for a new hub assignment.
4. For a hub-assigned final-mile COD parcel, scan departure, follow the current
   buyer stop and record the authorized test recipient, original image, exact
   received cash/change and explicit cash acknowledgement. Verify one delivered
   checkpoint and collection. Buyer receipt and remittance stay separate.
5. Prepare a separate failed-attempt scenario. Use the returned reason policy,
   notes, place and original image. Confirm one attempt and retained rider return
   responsibility until the destination hub independently receives the parcel.
6. Check retained history and private images after an authorized reassignment.
   A later rider must not read the original assignment's proof. Denied/changed
   proof clears the viewer. Leaving the app or signing out clears private images;
   returning requires revalidation and deliberate reopening.
7. Check real camera denial/cancellation, picker interruption and Android lost-data
   recovery. A restored photo remains an unsubmitted draft for its original
   account, task, action and version. An uncertain command retains its original
   UUID, scalar fields and proof; it cannot be replaced to bypass reconciliation.

To run the ordinary app on a connected Android phone:

```sh
flutter devices
flutter run -d <android-device-id> --dart-define-from-file=.env.geoapify.json
```

Keep login details, bearer tokens and actual private proof outside Git and logs.
Record sanitized result/command references and the owning-role observations.
Do not repeat the previously accepted HDB-05 claim as a new test.
