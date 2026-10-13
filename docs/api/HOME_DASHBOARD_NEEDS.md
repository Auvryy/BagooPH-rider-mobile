# Home/dashboard API needs checklist

Requested October 13, 2026. This is the Rider Mobile coordination checklist for
the [Home branch plan](../plans/home-dashboard-branch-plan/README.md). It is not a
new wire specification or authorization to change the website. The API owner
keeps the contract, executable OpenAPI, source fixtures and rollout evidence.

Initial backend reference: `0571f75d10cac0dc9f7da9875e4d801fdc941bdc`; the later
read observed `10619cea9fac27a642533e401180f6a618f72158` on
`fix/registration-contact-uniqueness`, still with unrelated work in progress.
The checked Home API/services retained their initial fingerprints. Operations OpenAPI remains `1.0.0`, 25
methods/24 paths, fingerprint
`8b09acf2e933441ee766820c94f65eafe1240c6c343b659e89487c6ab1e507eb`.
The final read observed clean backend main at
`b91f13a57c7fedbd0252b0d98eeefe834b160aee` after its owner's merge; the Home/API
fingerprints remained unchanged. The account source/docs mismatch below still
needs owner clarification. None of this identifies the deployed Azure commit.
Checked source items below establish implementation only; unchecked live items
require fresh evidence and must not be cleared by local fixtures.

## What to ask for first

Verify current Azure deployment and provide authorized isolated resources for
native Home, owned detail, duty and one pickup claim. Existing APIs already
cover the core operations; do not request duplicates. Coordinate only a selected
missing field/behavior after comparing the current owner contract and code.

<a id="api-h01"></a>

## API-H01 — Existing source contract and dashboard data

- [x] Native Home, available pickups, pickup/final-mile queues, owned task detail,
  duty, claim and command reconciliation routes exist in source.
- [x] Home provides actual company/hub/coverage, duty, eligibility/denial,
  active/limit/remaining pickup capacity, the three queue counts, observed_at,
  capabilities and limits. These support the initial dashboard improvements.
- [x] Tasks provide phase, commercial/operational state, custody, current stop,
  exact permitted payment, action hints/denials, assignment reference and instructions.
- [x] Native parcel, Trips/proof, messages, notices and cash adapters exist in
  source; their unfinished Flutter consumers are not new missing backend endpoints.
- [ ] At each branch activation compare current routes/OpenAPI/fixtures and DTOs;
  document any later schema/behavior change before making the consumer depend on it.

<a id="api-h02"></a>

## API-H02 — Deployment and fresh authorization evidence

- [ ] Obtain the actual deployed revision, target-relative migration status and
  runtime route availability, including rider_commands and the required Settings,
  checkpoint/attempt/COD journal sources such as cod_cash_events.
- [ ] Obtain a fresh approved native session with operations_api_version: 1 and
  the narrow read/work/messages/notifications/cash abilities; preserve holding,
  account, logout and Settings compatibility.
- [ ] Read Home capabilities and limits too; version discovery alone does not
  prove that every later feature schema/service is available.
- [ ] Verify private first-party HTTPS JSON, no-store/no-cache/nosniff, safe
  request IDs and numeric cooldown/error semantics, including proof reads.
- [ ] Verify old/expired/missing abilities, wrong actor, reassigned/hidden task
  and restricted account rejection without ordinary native recovery privileges.
- [ ] Recheck the merged account/identity changes when their actual target is
  deployed, including target-required migrations such as the October 13 contact
  uniqueness migration. The source merge proves no Azure rollout or data acceptance.
- [ ] Resolve the inspected registration source/options sex_required:true versus
  owner-doc paragraph sex_required:false. Compare the mobile application fields
  and accepted new-password policy; use the separate
  [account compatibility follow-up](../plans/home-dashboard-branch-plan/ACCOUNT_COMPATIBILITY.md),
  not an unrequested account rewrite inside a Home fix.

Older October 9 404 evidence predates later successful mobile Home/empty-queue
reads. Report current deployment rather than treating either dated result as today.

<a id="api-h03"></a>

## API-H03 — Authorized test resources and cross-role observations

- [ ] Supply an approved placed rider with eligible company/hub/coverage/vehicle,
  and a genuine ready-for-pickup parcel in that origin-hub scope.
- [ ] Supply the actual waybill and authorized seller/origin-hub actors for
  collection followed by real hub intake.
- [ ] Supply a separately hub-assigned final-mile COD parcel after the mandatory
  Mother-Hub/destination-hub flow, with a valid saved buyer destination if routing is tested.
- [ ] Supply a separate failure/return/retry scenario with actual attempts and
  destination-hub receipt authority.
- [ ] Supply retained Trip/private proof, permitted seller/buyer conversation,
  delivered durable notice and retained rider cash responsibility for later branches.
- [ ] Observe native command results in the owning website/hub/buyer/cash records.
  Record assignment, collection, hub intake, delivery, buyer completion and cash
  recipient receipt as separate events.

Resources must be isolated and authorized through the real owning workflows.
No production reseed/reset, forced status/ownership or direct seller-to-buyer
shortcut is requested. Share credentials/resource context privately, not in this file.

<a id="api-h04"></a>

## API-H04 — Replay, uncertainty, versions and limits

- [x] Every operational write requires the actor-scoped lowercase UUID
  Idempotency-Key; X-Request-ID is separate correlation.
- [x] Same intent returns the original committed result; conflicts, unknown and
  expired intents have explicit semantics. Replay window is seven days, and the
  retained result remains readable after retry expiry.
- [x] Parcel/claim versions are opaque lowercase 64-character hex; cash offer
  versions are journal-sequence ID strings. Decimal IDs and exact cents stay strings.
- [ ] Verify native desired duty/claim, same-key replay/reconciliation,
  changed-body rejection and stale/competing assignment on accepted deployed source.
- [ ] Verify later multipart/message/read/cash command results under the same
  recovery rules; no silent new key after timeout or COMMAND_UNKNOWN.
- [ ] Confirm the shared native IP budget and write cooldowns during combined
  polling/navigation. Current source is 30 requests/minute and additional 10/minute
  write limits; foreground dashboard refresh starts at 30 seconds.

<a id="api-h05"></a>

## API-H05 — Physical parcel commands and private proof

- [x] Distinct pickup/depart/deliver/fail commands use actual submitted scan,
  fresh parcel revision and shared domain services.
- [x] Deliver/fail require genuine JPEG/PNG/WebP proof, maximum 5,242,880 bytes;
  retries fingerprint original bytes and retained proof reads are owned/hash checked.
- [x] Successful native delivery is currently COD-only. Non-COD actions remain
  denied with UNSUPPORTED_PAYMENT_OUTCOME; no zero-cash workaround is requested.
- [x] Failure policy supplies reasons, notes/location/image requirements, actual
  recorded count/limit and return hub; retry/RTS and hub receipt remain owner actions.
- [ ] Verify deployed multipart limits permit the advertised file plus form
  overhead, private storage survives rollout, and rejection/rollback does not lose
  previously accepted evidence or retain an unused new upload.
- [ ] Verify wrong scan, stale/reassigned/terminal task, duplicate outcome,
  incorrect recipient/cash and foreign/changed proof cannot advance state.
- [ ] Complete the owner's legacy public-proof review before claiming release
  privacy. New private writes do not revoke older public URLs; no historical
  deletion/migration is authorized by this checklist.

<a id="api-h06"></a>

## API-H06 — Current-stop coordinates, guidance and vehicles

- [x] Current native coordinates are buyer-only. Seller and both hub stops return
  null; the client must retain addresses and never guess a destination.
- [x] LogisticsHub and browser hubPayload already contain saved hub coordinate
  fields. Native exposure, validity and current-stop ownership need a selected extension.
- [x] Buyer stop.instructions contains authorized stored order notes. It does
  not establish structured landmark/floor/access-photo fields or seller/hub instructions.
- [x] Settings already supplies managed vehicle_type. Registered supported values
  choose routing; unrecognized values require explicit profile choice.
- [ ] Fix the mobile mapping for the actually registered Sedan / Van alias
  (BUG-H05/HDB-02). Do not treat this valid known alias as an unknown vehicle.
- [ ] If hub routing is selected, expose valid saved coordinates only for the
  actual authorized origin/destination hub stop; retain null fallback and changed-stop semantics.
- [ ] If seller routing is selected, agree a reviewed pickup-coordinate source,
  validation and immutable parcel pickup snapshot. Do not reuse delivery POD
  coordinates or a future buyer stop as the seller location.
- [ ] If richer Doorstep Guide is selected, agree each field's author/update
  authority, phase visibility and destination-change rules; preserve the frozen address.
- [ ] Verify the owned seller contact mapping: RiderTaskService reads
  pickup_contact_phone, while the inspected Delivery model/schema and browser
  pickup payload use pickup_phone; no matching accessor/column was found in that
  review. The API owner should test the intended owned contact and preview privacy.
  This is a source discrepancy to verify, not a claimed live response.
- [ ] Clarify canonical vehicle vocabulary/mapping, including existing fleet
  types motorcycle/tricycle/l300_van/wing_truck, without silently forcing a driving profile.
- [ ] Any selected extension updates owner docs/examples/OpenAPI and tests for
  privacy, invalid/missing pairs and changed/reassigned destinations before activation.

Address-first Stop Mode and pickup claims can proceed without these conditional
coordinate extensions. Geoapify configuration and Android location service are
already client concerns; no fleet GPS-upload API is requested.

<a id="api-h07"></a>

## API-H07 — Messages and durable notices

- [x] Native conversation IDs retain phase/delivery/assignment/participant. Sends
  and displayed through_message_id reads reuse the existing messaging service.
- [x] Native notices provide an authoritative unread_count and authorized/nullable
  targets. Notice read-through accepts the exact displayed owned UUID list.
- [ ] Verify the deployed notifications:deliver-pending scheduler and relevant
  worker configuration produce durable actual events.
- [ ] Verify stale participant/assignment, foreign read ID, late unseen arrival,
  duplicate/uncertain send/read and reauthorized target handling.
- [ ] If a global unread-chat badge is selected, supply or agree an authoritative
  all-owned-thread aggregate. Current per-thread counts on one page do not prove a
  complete unread total; a plain Messages shortcut needs no new endpoint.

<a id="api-h08"></a>

## API-H08 — Cash responsibility and offer-only remittance

- [x] Cash list/detail and offer exist; list summary explicitly covers all owned
  journals, while detail provides permitted hub recipients and current sequence.
- [x] Offer is awaiting_recipient_receipt. Held/remitted facts change only through
  the recipient's separate receipt; rider receive/reconcile/earnings are unavailable.
- [ ] Verify authorized isolated native offer -> real hub receipt -> website
  journal parity with exact amount/version, replay, discrepancy and private access.
- [ ] Keep earnings available:false / confirmed_cents:null unless a separately
  selected authoritative earnings writer and contract have been accepted.

<a id="api-h09"></a>

## API-H09 — Optional additional dashboard data

- [ ] Before adding Delivered today or a full chart, agree the native aggregate's
  exact actor/history scope, delivery-event date basis, Asia/Manila boundary and
  completeness. Home currently returns only three work counts, not these metrics.
- [ ] Do not derive a full daily count from the browser's latest-ten chart or a
  paginated native Trip list whose dates are assignment_recorded_at.
- [ ] If richer two-stop details are selected, agree authorized next-stop data
  instead of inventing its address/contact from a single current-stop response.
- [ ] If server task search is selected, agree query/field/limit/total semantics;
  current local search is over loaded rows and can be labelled without an API change.
- [ ] Keep release, native restricted recovery, non-COD delivery and earnings in
  separate chosen contracts; no new generic status or privileged recovery route is requested.

These optional requests do not block HDB-01–04, existing counts/capacity or the
selected first duty/claim acceptance. Personal session-only Parcel Finder labels
need no backend mutation or synchronization endpoint.

## API-owner return checklist

- [ ] Dated source/deployed revisions and exact migration/route evidence.
- [ ] Fresh allowed/denied native results with safe request IDs and no credentials.
- [ ] Authorized isolated resources and the observed owning-role events.
- [ ] Accepted existing behavior versus a precise missing field/behavior, with
  local tests, Azure behavior and physical-device evidence kept distinct.
- [ ] For any selected extension, its owner contract/examples/test and publication/
  rollout handoff; leave unselected future requests unchecked.

Refer to the existing [native deployment gate](../plans/native-operations/DEPLOYMENT_GATE.md),
[shared consumer rules](../plans/native-operations/CONSUMER_RULES.md) and
[Home evidence](../plans/home-dashboard-navigation/EVIDENCE.md). This checklist
does not replace those owners or rewrite their dated evidence as current acceptance.
