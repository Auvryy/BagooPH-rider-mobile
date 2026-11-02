# Paid Wallet delivery alongside COD

Selected October 22, 2026 on `feat/rider-prepaid-delivery`, from merged Rider
main `9806ce5`. This extends the existing
[pickup/delivery/Trips implementation](../rider-orders-delivery-trips/README.md).
The client supports the additive paid Bagoo Wallet contract. Local retained
proof compatibility is accepted against the fixed source branch; live activation
remains gated by merging/deploying that source and controlled acceptance.

## Sources and boundaries

- Backend reviewed read only at `99e5895f98159334e372df4f43659fda0bd43960`:
  `docs/api/RIDER_OPERATIONS_API.md`, `RiderTaskService`, `RiderParcelController`,
  `WalletHandoverService`, `RiderTripService` and `WalletDeliveryTest`.
- The backend's original paid payment source and current `deliver` action hint
  establish eligibility. A paid label or missing COD amount alone cannot.
- Associations: [M07.05–06 and M07.10–13](../../SUBTASK_BACKLOG.md),
  [M11](../../TASK_TRACKING.md#m11--trips-and-recorded-history),
  [OPS-02](../native-operations/02-scan-parcel-work.md) and
  [OPS-03](../native-operations/03-trips-private-proof.md). Their broader live
  and physical acceptance is separate; this extension completes no whole area.
- Reuse the implemented M01 protected commands/proof, M02 forms/platform
  adapters, M03 account isolation, M04 capabilities and M06 custody foundation.
  Their outstanding deployed/physical gates are not cleared by this extension.
- Existing account, navigation, pickup, failures, Messages, Notifications and
  cash-remittance behavior retain their original scope. No backend edit,
  Azure write, substitute account, phone requirement or new map key is selected.

Estimated client effort: **10 hours**, October 22–25 (four inclusive calendar
days), within the [delivery deadline](../../DELIVERY_PLAN.md). Waiting for
owner/device acceptance is separate from active development.

## Implemented behavior

1. Current owned final-mile detail distinguishes exact COD, evidenced paid
   Wallet and unavailable payment instructions. Home, task detail and Stop Mode
   use the same wording. Available pickup previews expose no payment details.
2. COD retains received cash, change and explicit confirmation. Eligible paid
   Wallet delivery displays **Paid — no cash to collect** and omits all cash
   fields. Both require the actual waybill, recipient/relationship and original
   image through the existing delivery endpoint.
3. Fresh detail must match the reviewed assignment, version and payment terms.
   A changed method, status or COD amount invalidates the review even when the
   opaque version is unchanged. Scan, cash confirmation and proof need review
   again. Unsupported or unpaid sources stay unavailable.
4. The protected journal stores an optional local Wallet discriminator. It is
   absent from HTTP. Legacy COD records still require their original cash
   fields; uncertain Wallet commands retain the original UUID/body/image across
   restart. A known saved result can reconcile with writes disabled; an unknown
   retry still needs all applicable write gates.
5. Retained Trips labels Wallet accurately, returns the recipient from the
   matching immutable Wallet receipt and serves the original private proof. It
   keeps cash fields unavailable and never substitutes the parcel's current
   recipient for original-assignment evidence.

`PREPAID_DELIVERY_WRITES_VERIFIED` defaults to false and is required in addition
to `PARCEL_WRITES_VERIFIED`. Neither local tests nor accepted duty/claim
verification activate prepaid writes. Ordinary builds still use Azure account
access and the existing private map configuration.

## Source acceptance and remaining gates

Bagoo's source repair was developed on branch `fix/rider-wallet-trip-evidence`
through `9e58312d130809eb8cd878189b729f1f702291d8` and later merged by PR #144
at `9ca5db5`. The focused backend suite passed
452 tests and 16,115 assertions. The native Linux client then passed the pinned
handoff/replay flow: one completed paid delivery, one Wallet receipt, one
delivery command, zero COD accounts, the original recipient and exact
hash-matched private proof bytes in Trips.

This accepts the source contract only. Bagoo PR #144 later merged the backend
fix into `main` at `9ca5db5`; Azure deployment, fresh capability discovery and
controlled owned-resource acceptance remain open. The
[API checklist](../../api/PREPAID_DELIVERY_NEEDS.md) tracks those deployment and
live gates. See [testing](TESTING.md) and the [verification record](VERIFICATION.md)
for local evidence and its limits. Prepaid writes remain disabled until the
separately authorized live acceptance passes.
