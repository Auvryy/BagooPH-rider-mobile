# Paid Wallet delivery API checklist

Consumer: [selected prepaid extension](../plans/prepaid-delivery/README.md).
Reviewed October 22, 2026 against backend
`99e5895f98159334e372df4f43659fda0bd43960`. Keep the earlier
[parcel/Trips](ORDER_DELIVERY_TRIPS_NEEDS.md), [Messages](MESSAGES_NEEDS.md) and
[Notifications](NOTIFICATIONS_NEEDS.md) acceptance requests cumulative.

## Confirmed local contract

- [x] Existing delivery endpoint accepts evidenced paid Wallet with actual
  waybill, expected version, recipient/relationship and original private image.
- [x] `payment.method: wallet`, paid commercial status, null COD due and the
  fresh permitted delivery action distinguish the supported source.
- [x] The mobile request omits cash fields. Original protected UUID/body/image
  recovery and replay produced one Wallet receipt and zero COD accounts in the
  real native-to-kernel check.
- [x] COD retains its exact received-minus-change and cash confirmation flow.
- [x] A separate default-false `PREPAID_DELIVERY_WRITES_VERIFIED` gate prevents
  local compatibility evidence from activating live prepaid writes.

## Concrete backend owner work

- [ ] Fix `RiderTripService::checkpointProof` to resolve an original paid Wallet
  delivery's immutable receipt/proof evidence. Its unconditional `CodAccount`
  lookup currently returns 404 despite the returned retained proof link. Verify
  original assignment/checkpoint/actor ownership, hash and private/no-store
  response behavior. Do not manufacture a COD account or reuse unrelated proof.
- [ ] Return the original Wallet recipient from the matching immutable handover
  receipt in retained Trips. Current detail derives recipient only from a COD
  collection, so it returns null despite a saved Wallet recipient. Do not fall
  back to edited current-order or later-assignment recipient information.
- [ ] Add owner tests for paid Wallet original proof/recipient, later
  reassignment, another rider denied, changed proof rejected, original command
  replay and unchanged COD private proof. Update native assertions to require
  the corrected behavior and rerun against the fixed revision.

## Deployment and controlled acceptance

- [ ] Confirm the actual Azure commit and applicable Wallet payment/handover,
  command, checkpoint and private-proof migrations after the fixes are deployed.
- [ ] Fresh private login advertises operations v1 and the deployed Home
  parcel/Trips capabilities; inspect actual owned detail and action hints.
- [ ] Designate isolated approved-rider COD and paid Wallet assignments through
  the normal buyer/hub workflows, sequentially respecting duty, hub and active
  work eligibility. Supply sanitized references and permitted test evidence;
  credentials are entered privately. Do not repeat an already accepted claim.
- [ ] Independently confirm one delivery/receipt and original replay, no cash
  collection for Wallet, unchanged COD amounts, retained original private proof
  and recipient, and denied foreign proof. Buyer completion, hub receipt and
  remittance remain separate owning actions.
- [ ] Enable prepaid writes only after this acceptance. Existing parcel
  activation is also required; duty/claim acceptance is insufficient.

No new endpoint or API key is requested. Physical Android acceptance can follow
when a phone is available. The mobile work does not authorize backend edits or
production data preparation by the mobile agent. See the
[verification record](../plans/prepaid-delivery/VERIFICATION.md) for evidence.
