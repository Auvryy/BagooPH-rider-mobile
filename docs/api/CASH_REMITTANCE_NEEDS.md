# Cash records and remittance API checklist

Consumer: [selected Cash & Remittance client](../plans/rider-cash-remittance/README.md),
[OPS-05](../plans/native-operations/05-cash-remittance.md), M15.
Reviewed October 22, 2026 against committed backend
`89ad0b923e38af459d3d59be993c140af63b3e5b`. Concurrent website work is preserved.
No new endpoint or API key is requested from the existing source contract.

## Existing source contract

- [x] `GET rider/cash` supplies owned retained journals, pagination/search,
  all-owned held/difference summary and explicitly unavailable earnings.
- [x] `GET rider/cash/{id}` supplies original journal facts/history, signed
  discrepancies, current positive-decimal sequence version and permitted hub
  recipients. Values are exact cent strings, never binary-float balances.
- [x] `POST rider/cash/{id}/offer` accepts only `expected_version`, `recipient_id`,
  exact peso `amount` and `evidence_reference`, with an original UUID header.
- [x] An offer is `awaiting_recipient_receipt`; only the recipient's separate
  owning workflow records receipt and changes held/remitted balances.
- [x] Commands retain original replay/lookup, conflicts and seven-day expiry.
  No rider receive/reconcile/earnings/bank-transfer/payout route is provided.

## Required before live offer activation

- [ ] Confirm the actual deployed Azure commit and compatible cash schema,
  including `2026_10_08_180000_create_cod_cash_records` and
  `2026_10_09_010000_create_rider_commands_table`, plus current source dependencies.
  Preserve append-only history; a source checkout is not deployment evidence.
- [ ] Fresh private login advertises operations v1; actual Home cash capability,
  operational read ability and `rider:operations:cash` are present. Confirm
  missing/old/foreign abilities deny access without breaking account screens.
- [ ] Designate an isolated approved rider with a genuine retained COD cash
  source and a current eligible hub recipient. Agree exact test amount and
  permitted plain software-test handover reference. Supply sanitized references;
  credentials remain private. Never create a balance by editing a projection.
- [ ] Compare all-owned summary, filtered pages, detail and retained history with
  the owning website journal. Off-duty and changed placement preserve authorized
  recorded responsibility; restriction never grants broader recovery authority.
- [ ] Observe exactly one deliberate offer/original command; held/remitted stay
  unchanged until the independent authenticated hub receipt. Compare subsequent
  balances and signed discrepancies, retaining append-only source references.
- [ ] Verify stale source, wrong recipient/amount/actor, unknown/expired/conflicting
  original request recovery and private/no-store/rate-limit behavior on that
  deployment without deleting retained commands.
- [ ] Accept this scope before enabling the separate default-false
  `CASH_WRITES_VERIFIED` gate. Duty/claim, parcel or Wallet acceptance cannot
  enable cash offers. Phone acceptance remains a separately recorded check.

## Independent outstanding requests

Keep the earlier [parcel/Trips](ORDER_DELIVERY_TRIPS_NEEDS.md),
[Wallet retained proof/recipient](PREPAID_DELIVERY_NEEDS.md),
[Messages](MESSAGES_NEEDS.md) and [Notifications](NOTIFICATIONS_NEEDS.md)
requests cumulative. Earnings remains unavailable until its own contract exists.
This mobile feature does not authorize backend edits or unrelated production
cash actions. See [verification](../plans/rider-cash-remittance/VERIFICATION.md)
for final local evidence and its limits.
