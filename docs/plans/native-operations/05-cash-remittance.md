# OPS-05 — Cash records and remittance offers

State: **planned, not activated**. Needs shared access/command foundation and real
retained cash responsibilities/outcome records. Associations: B15-A–B15-B and
supported refresh/acceptance portions of B15-C; M15.09 earnings remains unsupported.

## Contract and implementation slices

GET `rider/cash`, `rider/cash/{account}`; POST `/rider/cash/{account}/offer`.
Follow the same-origin prefix; exact required fields are backend-owned.

1. Decode retained journals, held/remitted/collected/pending/excess/discrepancy and
   reconciliation facts separately. Exact cent strings remain exact at large
   values. The list summary covers all owned journals, not only a filtered page.
2. Read allowed hub recipients and the current journal sequence. Offer sends
   `expected_version`, `recipient_id`, exact peso `amount` and `evidence_reference`.
   This version is an **ID-range sequence string**, not the parcel's hex revision.
3. Persist/reconcile the original cash intent through timeout/restart and refresh
   current journal/offer history. An offer is `awaiting_recipient_receipt`; it does
   not change held/remitted facts until the hub's separate authenticated receipt.
4. Present labelled unavailable earnings with null confirmed value. COD, shipping
   and seller commission are not rider income. No rider receipt, bank transfer,
   reconciliation, payout or withdrawal action is added.

Primary ownership: finance models/repository/controller/views and exact amount
formatting. Backend append-only decisions remain server-owned; shared transport,
permissions and command storage are coordinated foundation work.

## Finish evidence

- Local tests cover exact cent/peso conversions, sequence validation, allowed
  recipients, stale/conflicting/expired intent and retained responsibilities.
- A real authorized Azure offer is observed as an offer; held/remitted values
  change only after the hub receipt. Platform reconciliation remains separate.
- Wrong actor/recipient/version/amount cannot succeed; original retries cannot
  create another offer. Confirm native UI and website journal parity.
- Actual Android amount/reference entry, resume/reconciliation and privacy work.
  Unavailable earnings or unknown source facts are never displayed as guessed zero.
