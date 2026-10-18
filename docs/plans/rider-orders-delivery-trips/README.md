# Pickup acceptance, delivery and retained Trips

Activated October 18, 2026 on `feat/rider-orders-delivery-trips` by the request to
build accepting orders, delivering and Trips. This selects the related shared
foundation, pickup, departure, COD/failure and retained-history work together;
it does not activate messages, notifications or cash-remittance offers.

## Source and scope

- Mobile base: merged main `3c68857`, including HDB-05 and the current design.
- Backend reviewed read only: `14b589fda2708b80903990881ac4da4286b23dc3`.
  Concurrent website navigation changes are outside this mobile work.
- The backend's [operations contract](https://github.com/Auvryy/BagooPH/blob/14b589fda2708b80903990881ac4da4286b23dc3/docs/api/RIDER_OPERATIONS_API.md),
  executable OpenAPI, parcel controller, task/trip/command services and tests own
  fields, validation, custody and cash. No backend edits are authorized here.
- Last accepted live evidence is HDB-05 at deployed `c262473`. It establishes
  duty/claim acceptance, not current parcel, private-proof or Trips acceptance.
  See the [API checklist](../../api/ORDER_DELIVERY_TRIPS_NEEDS.md).
- Associations: [OPS-02](../native-operations/02-scan-parcel-work.md),
  [OPS-03](../native-operations/03-trips-private-proof.md), and HDB-06–11 in the
  [Home branch plan](../home-dashboard-branch-plan/README.md). The user selected
  these flows together; internal commits replace their separate-branch sequence
  for this work. Their physical/live finish evidence remains required.
- Related areas: [M06–M08 and M11](../../TASK_TRACKING.md), with shared M01–M03,
  M09 and M16 prerequisites. Existing account, Settings, navigation and handover
  behavior must remain compatible. No whole backlog card is completed by naming it.

Estimated client effort: **36 hours**, excluding owner/device waiting. Working
window: **October 18–27** (10 inclusive calendar days), within the existing
[delivery deadline](../../DELIVERY_PLAN.md). Re-estimate from actual findings.

## Implementation and commit sequence

1. Record this scope, source review, API needs and acceptance matrix.
2. Extend the existing account/API-scoped command journal for selected parcel
   intents and protected original proof; preserve stored duty/claim records.
3. Add real Android waybill capture, explicit pickup/departure review and
   server-confirmed collection/departure, with refreshed task and route state.
4. Add recipient/proof and exact COD delivery, failure reasons/notes/location,
   return guidance and uncertain-request recovery.
5. Connect server-filtered retained Trips, original-assignment detail, bounded
   pagination and authenticated private image reads.
6. Complete meaningful regression/native-build checks, render review and an
   owner handoff for any remaining Azure/physical acceptance.

Each implementation commit includes its relevant tests and documentation.
Later review fixes receive their own focused commits. The user handles pushes.
See the [testing steps](TESTING.md) for PC review, local verification and the
separate controlled Azure/Android acceptance procedure.
The [verification record](VERIFICATION.md) separates passed client/native checks
from outstanding deployed and physical acceptance.

## Interaction and implementation decisions

- Keep the existing One Red tokens and bundled typography from
  [DESIGN_SYSTEM.md](../../DESIGN_SYSTEM.md). Use normal scrolling, labelled
  controls, a bounded form width, safe areas and text scaling to 200%.
- Apply the selected existing UI/UX and Flutter layout skills to clear action
  reviews, inline validation, loading/uncertainty feedback and responsive forms.
- Available orders are pickup previews. A claim establishes assignment only.
  Refreshed owned detail supplies the actions available to the rider.
- Final-mile work is assigned by the destination hub. The rider never self-assigns
  delivery, receives parcels on behalf of a hub or completes the buyer's order.
- Actual captured waybill values are reviewed and submitted. Stored tracking
  numbers and typed test values never stand in for physical scan evidence.
  Linux retains browsing, proof selection and route preview; camera acceptance
  requires supported native hardware.
- New native successful delivery is COD-only under the current contract.
  Amounts use exact decimal strings/integer cents. Cash remittance and earnings
  remain distinct from recorded collection.
- Retain one unresolved ordinary work intent, its original body/key/version and
  original proof bytes across restart/logout. Reconcile before retrying; do not
  replace a key, file, recipient or amount to bypass an uncertain outcome.
- Private proof is retained only for recovery, partitioned by account/API, and
  removed after a verified result or definitive rejection. Private history proof
  is held in memory only and cleared on access/account/lifecycle changes.
- Loading/empty/denied/unavailable/stale/failed/uncertain states stay distinct.
  Server capability and operational hints gate new writes; the server checks
  current authority again. No fixture enables a live operational gate.

## Evidence matrix

| Requirement | Evidence needed | Current state |
|---|---|---|
| Existing acceptance remains usable | Duty/claim regression, refreshed owned detail, original command replay | HDB-05 baseline preserved; local regression and native kernel scenario passed; new live scope pending |
| Protected parcel intent | Persist-before-dispatch, original-byte hash, interrupted upload, restart/logout/account isolation, unknown/expired/conflicting replay | Local tests and native Linux protected-storage/original-proof recovery passed; live/Android extension pending |
| Pickup/departure | Correct/wrong scan, stale/reassigned task, action denials, duplicate taps, refreshed custody/stop and cancelled old route | Client connected; selected controller/layout regressions passed; actual camera/live checks pending |
| COD delivery | Real image validation, recipient evidence, exact received-minus-change, one outcome/collection and separate buyer completion | Client connected; selected local form/command tests passed; live/physical verification pending |
| Failed delivery | Server reasons/attempt count, proof and notes, retained rider return responsibility until hub receipt | Client connected; selected local tests passed; live hub return verification pending |
| Trips | Original retained attribution, pickup/final-mile distinction, exact money, Manila assignment dates, server filters/pagination and late-result cancellation | Client connected; local contract/controller/layout checks passed; live acceptance pending |
| Private proof | Same-origin approved path, no redirects/public URL, size/type/privacy checks, denied/changed bytes and visible-state cleanup | Local transport/privacy/cache checks and native kernel ownership/hash checks passed; live acceptance pending |
| Responsive UI | Narrow phone and desktop, 200% text, keyboard/Back, loading/errors, bottom-nav clearance and render review | Selected local layout checks and synthetic Trips render review passed; physical acceptance pending |
| Native verification | Relevant/full tests, analysis, ordinary Linux and Android builds | Full suite: 428 passed, four expected skips; analysis clean; ordinary Linux/Android builds and native kernel scenario passed |
| Azure and cross-role acceptance | Operator-confirmed deployment/migrations, authorized isolated parcels and owning hub/buyer/cash observations | Not established for this scope |
| Android physical acceptance | Actual scan permission/cancel, camera and proof-picker lifecycle, successful stop/outcome flow | Not established |

This package records the full selected objective. Local checks or APK builds do
not prove Azure/cross-role or physical-device acceptance. Outstanding acceptance
is reported explicitly rather than replacing real operations with mock success.

## Command/proof foundation evidence

The existing secure journal now accepts typed selected parcel commands while
preserving legacy duty/claim JSON. Original images use AES-256-GCM encrypted
application-support files bound to the API, account, command key and SHA-256;
the encryption key and original scalar intent fields use secure storage. No
plaintext proof file or bearer token is added to the journal. Confirmed results
and definitive rejections clean their referenced proof; unresolved requests
retain it across logout. A missing/changed original prevents replay, while a
retained committed result can reconcile without that local file.

`PARCEL_WRITES_VERIFIED` is a separate default-false acceptance switch. Existing
duty/claim activation does not enable physical parcel outcomes. Source Home
capabilities, refreshed owned action hints and the reviewed assignment/version
are also checked; received-minus-change uses exact integer cents.

The selected foundation run passed **37 tests, one expected alternate-API skip**,
including existing duty/claim, transport, token and configuration regressions.
New checks cover all four parcel actions, multipart original bytes, interrupted
upload/restart, account loss, changed result, expired/unknown/conflicting retry,
wrong/stale scan, storage failure and encrypted cross-account/API isolation.
No Azure parcel write or physical scan was performed by these tests.

New runtime dependencies were checked against Flutter 3.47.1 / Dart 3.13.1:
[cryptography 2.9.0](https://pub.dev/packages/cryptography) supplies authenticated
AES-GCM; [path_provider 2.1.6](https://pub.dev/packages/path_provider) provides
application-support directories on Android and Linux. Existing secure storage
continues to own key protection. Scanner/proof-picker dependencies are selected
in their implementation commit.

## Pickup/departure client evidence

Stop Mode now opens an explicit waybill review for available owned pickup or
hub-assigned departure actions. Android uses
[mobile_scanner 7.4.2](https://pub.dev/packages/mobile_scanner) with bundled ML Kit,
contextual camera permission, lifecycle stop/resume and disposal. Wrong/ambiguous
waybills keep scanning; there is no gallery, stored-code or typed scan substitute.
Linux reports camera unavailability and keeps task browsing available. Scan and
outcome pages close or clear private state when account/task authorization changes.

Collection refreshes the origin-hub responsibility; departure preserves the
final-mile queue and refreshes the buyer stop. A known terminal delivery removes
the active task without mistaking its expected hidden detail for a failed outcome.
An uncertain request stays blocked until its original result is reconciled; the
review then displays that confirmed result without a second action.

The selected workflow, duty/claim, Stop Mode and read-recovery run passed **63
tests**. Coverage includes real controller transitions, duplicate taps, access
loss, original-key recovery, narrow 320px and wide 900px review layouts at 200%
text, 48px controls and scanner privacy cleanup. These use isolated adapters and
do not establish actual Android camera or Azure parcel acceptance.

The selected proof-picker dependency is
[image_picker 1.2.4](https://pub.dev/packages/image_picker), compatible with the
current SDK and supporting Android lost-data retrieval plus Linux file selection.
Its proof-form integration and recovery checks are recorded below.

## Delivery, failure and photo recovery evidence

The selected outcome forms collect actual recipient evidence, original image
selection/capture and exact cash received/change with an explicit cash acknowledgement.
Failure uses the returned policy's reasons, recorded attempts and limit, required
notes/location/proof, then displays the refreshed destination-hub return instruction.
Missing policy and unsupported payment outcomes remain unavailable. No rider
button completes the buyer order, receives a hub return or records remittance.

Original photo drafts use the protected proof store and an encrypted picker
context. Android workspace startup checks lost picker data. A draft is offered
only to its original account/API/task/action/version and is restorable for 24
hours; expired drafts are cleaned when checked. Recovery never dispatches a
command, copies a later recipient or transfers a previous account's photo.
Persisted command originals have their independent unresolved-intent retention.
Private previews evict decoded image-cache entries on replacement/disposal.

The outcome command/proof/recovery selection passed **29 tests**. The combined
workflow, photo-recovery and outcome-page selection passed **25 tests**, including
320px/840px forms at 200% text, exact multipart fields/original PNG bytes, cash
mismatch rejection, safe correction after field rejection, required failure
evidence and private display-cache eviction. A missing Material ancestor and test
timer cleanup were corrected without suppressing widget assertions. These runs
establish local behavior; Azure and actual Android capture remain outstanding.

The later render review loads the bundled font and real image codec. It found
an invalid checksum in the inherited synthetic PNG; the app correctly blocked
that image. The parcel fixture now decodes successfully, and a codec assertion
prevents that false positive. Review labels wrap or use shorter wording at large
text sizes. The updated parcel/Trips regression selection passed **71 tests**,
with the selected narrow/wide forms rendered and reviewed. No live proof was used.

## Retained Trips and private image evidence

Trips now consumes server search by tracking/order number, phase/payment/date
filters, inclusive Manila assignment dates and incremental pages with stable-ID
deduplication. Query changes invalidate older responses. Search is debounced;
backgrounding cancels it. A server cooldown applies to both JSON and image reads
through the shared first-party transport. No earnings or unreturned handoff facts
are inferred.

Detail loads the original assignment afresh and distinguishes its checkpoints,
recipient, handoff, attempt proof and exact collection from the parcel's current
commercial/operational state. A proof download first revalidates the original
parent and advertised child path, then uses bounded authenticated image bytes
without redirects or public-storage URLs. Backgrounding, access loss, logout and
closing clear visible private data; decoded cache entries are evicted.

The selected Trips and shared-budget checks passed **25 tests**, including large
exact identifiers/money, null/unknown states, pagination, obsolete requests,
changed/denied proof, server cooldown and immediate logout cleanup. Synthetic
renders were reviewed at 375px and at 320px/900px with 200% text. The full Flutter
suite then passed **428 tests, four expected skips**; analysis was clean. Native
client-to-kernel and ordinary Linux/Android builds also passed; see the
[final verification record](VERIFICATION.md). These checks do not activate Azure
parcel writes.
