# Order acceptance, delivery and Trips API checklist

Owner: existing Bagoo Rider API. Consumer: the selected
[mobile implementation](../plans/rider-orders-delivery-trips/README.md).
Reviewed October 18, 2026 against backend `14b589f`. These checkboxes separate
available source contracts from live acceptance; no new endpoint is requested
unless implementation or verification exposes a specific gap.

## Source contract available

- [x] Version-1 account/Home discovery, current action hints and denial reasons.
- [x] Atomic duty and pickup claims with actor-owned retained UUID commands.
- [x] Owned task detail and pickup/depart writes with actual submitted waybill,
  opaque expected version and optional notes.
- [x] Multipart COD delivery with recipient, original private image, exact cash
  strings and explicit cash confirmation; server-owned, flow-version-specific
  order completion with COD remittance handled separately.
- [x] Failed delivery with allowed reasons, notes, location, original image,
  recorded attempts and return-hub guidance.
- [x] Retained original-assignment Trips with server search/phase/payment/date
  filters and stable paginated resources.
- [x] Original checkpoint/attempt proof through authenticated same-origin reads,
  hash verification and private/no-store response headers.
- [x] Explicit stale, denied, expired, unknown, changed-proof and quota responses.

## November 1 source revision follow-up

At the November 1 source review, Bagoo branch `fix/rider-wallet-trip-evidence`
at `9e58312d130809eb8cd878189b729f1f702291d8` included version-two automatic
order completion after verified recipient handoff; `main` was then
`f001d396b0e9ea6bfc2fdeb85ee24b66682b997e`, before the merge. PR #144 later
merged the source into `main` at `9ca5db5`. The Rider client displays the
returned commercial status and does not issue a buyer-confirmation command. COD
remittance remains independent. Merge is source evidence, not Azure acceptance.

## Required before Azure parcel writes

- [ ] Owning operator confirms the actual deployed revision and applied command,
  checkpoint, private-proof and COD-source migrations for this selected scope.
- [ ] Fresh approved Rider session advertises `operations_api_version: 1` and
  Home's actual parcel/Trips capabilities. Credentials are entered privately.
- [ ] Operator designates isolated current pickup and hub-assigned final-mile
  parcels, permitted recipients and genuine software-test evidence for the
  agreed acceptance actions. Existing live customer parcels are not substitutes.
  Prepare phases sequentially: active final-mile work blocks a new pickup,
  and new hub assignments require on-duty eligibility.
- [ ] Native reads establish Home, all queues, current owned detail, retained
  Trips and private-proof response behavior on that deployment.
- [ ] Controlled pickup/departure/COD/failure and original-key replay agree with
  the owning hub/buyer/cash records, with exactly one intended state transition.
- [ ] Actual hub receipt is observed through its owning workflow. Verify order
  completion against the deployed flow version: newer orders may auto-complete
  from verified recipient evidence; older orders retain buyer-owned completion
  where required. A mobile button cannot manufacture either result.
- [ ] Existing publicly exposed historical proof has the operator's separate
  release/retention review; this mobile task authorizes no deletion or migration.

## Device and operating checks

- [ ] Physical Android camera detects an actual parcel waybill; permission
  denial/cancel/wrong code and repeated detection leave custody unchanged.
- [ ] Proof capture/selection and Android lost-data recovery retain the correct
  account/task and original file bytes without silently submitting a draft.
- [ ] Restart, expiry, logout/account change and interrupted upload preserve the
  original unresolved request while clearing visible private state.
- [ ] Off-duty work remains reachable; reassignment/restriction removes ordinary
  actions and private evidence promptly.

Already accepted HDB-05 duty/claim evidence remains in its
[dated acceptance record](../plans/home-dashboard-branch-plan/HDB-05-EVIDENCE.md).
No additional map key is required for the parcel or Trips APIs. Existing
Geoapify configuration remains separate from authenticated Bagoo requests.
