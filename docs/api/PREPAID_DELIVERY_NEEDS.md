# Paid Wallet delivery API checklist

Consumer: [selected prepaid extension](../plans/prepaid-delivery/README.md).
Reviewed October 22, 2026 against backend
`99e5895f98159334e372df4f43659fda0bd43960`. Keep the earlier
[parcel/Trips](ORDER_DELIVERY_TRIPS_NEEDS.md), [Messages](MESSAGES_NEEDS.md) and
[Notifications](NOTIFICATIONS_NEEDS.md) acceptance requests cumulative.

**November 1 source follow-up:** the Wallet retained-proof/recipient code and
regressions are now on Bagoo branch `fix/rider-wallet-trip-evidence` through
`9e58312d130809eb8cd878189b729f1f702291d8`. Its focused backend suite passed
452 tests and 16,115 assertions. The Rider native prepaid consumer check also
passed against that pinned source. These results accept source compatibility;
they do not establish an Azure deployment, controlled live acceptance or
physical Android behavior. The write gates remain false.

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

## Source fix (completed on the review branch)

- [x] `RiderTripService::checkpointProof` resolves original paid Wallet evidence
  from the immutable receipt matched to delivery, checkpoint and actor. The
  response retains private/no-store behavior and validates the original image
  hash without creating a COD account or borrowing unrelated proof.
- [x] Retained Trips returns the original Wallet recipient from its matching
  receipt. It does not use the edited current-order recipient or a later
  assignment's recipient.
- [x] Backend regressions cover receipt identity mismatches, changed/missing
  proof, foreign access and reassignment. The native client now requires the
  original recipient, exact proof bytes/hash, one replayed result, one Wallet
  receipt and zero COD accounts.

The source changes are in Bagoo commits `15d7fc3` and `9e58312` on the branch
above. The [prepaid verification](../plans/prepaid-delivery/VERIFICATION.md)
records the pinned native run and limits.

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

No new endpoint or API key is requested. Source acceptance does not authorize
production data preparation or enable writes. Physical Android acceptance can
follow when a phone is available. See the
[verification record](../plans/prepaid-delivery/VERIFICATION.md) for evidence.
