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
| Existing acceptance remains usable | Duty/claim regression, refreshed owned detail, original command replay | HDB-05 baseline; extension verification pending |
| Protected parcel intent | Persist-before-dispatch, original-byte hash, interrupted upload, restart/logout/account isolation, unknown/expired/conflicting replay | Pending |
| Pickup/departure | Correct/wrong scan, stale/reassigned task, action denials, duplicate taps, refreshed custody/stop and cancelled old route | Pending |
| COD delivery | Real image validation, recipient evidence, exact received-minus-change, one outcome/collection and separate buyer completion | Pending |
| Failed delivery | Server reasons/attempt count, proof and notes, retained rider return responsibility until hub receipt | Pending |
| Trips | Original retained attribution, pickup/final-mile distinction, exact money, Manila assignment dates, server filters/pagination and late-result cancellation | Pending |
| Private proof | Same-origin approved path, no redirects/public URL, size/type/privacy checks, denied/changed bytes and visible-state cleanup | Pending |
| Responsive UI | Narrow phone and desktop, 200% text, keyboard/Back, loading/errors, bottom-nav clearance and render review | Pending |
| Native verification | Relevant/full tests, analysis, ordinary Linux and Android builds | Pending |
| Azure and cross-role acceptance | Operator-confirmed deployment/migrations, authorized isolated parcels and owning hub/buyer/cash observations | Not established for this scope |
| Android physical acceptance | Actual scan permission/cancel, camera and proof-picker lifecycle, successful stop/outcome flow | Not established |

This package records the full selected objective. Local checks or APK builds do
not prove Azure/cross-role or physical-device acceptance. Outstanding acceptance
is reported explicitly rather than replacing real operations with mock success.
