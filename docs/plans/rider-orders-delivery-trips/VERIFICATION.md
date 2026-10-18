# Implementation and verification record

October 18, 2026 · branch `feat/rider-orders-delivery-trips` · base `3c68857`.
This records implemented client behavior and its evidence. Controlled Azure and
physical Android acceptance remain unfinished parts of the selected objective.

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
- Exact received/change and the cash balance agreed. Native delivery left buyer
  receipt and reconciliation separate; the buyer's own workflow then completed
  the order without reconciling cash.
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
