# Cash records and protected remittance offers

Selected October 22, 2026 on `feat/rider-cash-remittance`, from Rider main
`a371e2e` (prepaid delivery PR 31). This activates
[OPS-05](../native-operations/05-cash-remittance.md): the read-only cash dashboard
and detail first, followed by protected remittance offers through the existing
native API. It does not activate earnings, receipt, reconciliation or banking.

## Source review and prerequisites

- Backend committed reference: `89ad0b923e38af459d3d59be993c140af63b3e5b`.
  Concurrent website parcel-workspace changes are outside this work; the
  selected cash controller/services and executable schema matched committed
  source when reviewed. Native verification passed against immutable snapshot
  `43558b3cbc53c4449704d6647681b5444fad3f62`, with identical selected cash
  sources and schema. It uses an archived snapshot,
  preserving the website's working branch and in-progress edits.
- Authoritative sources: `docs/api/RIDER_OPERATIONS_API.md`, executable
  `rider-operations.openapi.json`, `RiderCashController`, `RiderCashService`,
  `RiderCommandService`, `CodCashService`, `CodCashViewService`, and the owning
  cash cases in `RiderConnectedApiTest`. The current backend roadmap and normal
  buyer/courier/hub workflows were reviewed; schema is not inferred from UI.
- [M15](../../TASK_TRACKING.md#m15--cod-remittance-and-earnings-visibility):
  selected B15-A/B15-B, supported M15.10 refresh and local M15.11 verification.
  M15.09 confirmed earnings remains unsupported. No whole backlog card is marked
  complete by naming it or by passing isolated compatibility checks.
- Direct/transitive dependencies include M01 contract/protected commands,
  M02 transport/forms, M03 fresh-account access, M04 capabilities, M07 original
  cash collection, M09/M11 source links, M13/M14 entry points and M16 lifecycle.
  Existing code supplies this foundation. AUTH/FINANCE/HUBS/OUTCOMES/STAGING and
  applicable device gates remain separate; local fixtures do not clear them.
- Source availability is not current Azure evidence. The existing
  [deployment gate](../native-operations/DEPLOYMENT_GATE.md) accepts duty/claim
  only. Cash writes need their own deployment and cross-role acceptance.

Estimated client effort: **16 hours**, October 22–27 (six inclusive calendar
days), within the [delivery deadline](../../DELIVERY_PLAN.md). One coding agent
implements the client while the coordinating agent reviews contracts, owns
documentation and independently verifies native compatibility. Publication
remains user-controlled.

## Selected behavior

1. Open Cash & Remittance from Profile and authorized cash notices. Read actual
   owned journals, a server all-owned held summary, unresolved-difference count,
   search/pagination and original history. Filtering a page never changes the
   meaning of the all-owned summary.
2. Detail separates own held, actually remitted, collected, pending, excess,
   discrepancy and platform-reconciled facts. Format integer cents exactly,
   including signed history amounts. Earnings stay explicitly unavailable.
3. Offer only a positive exact peso amount within a freshly revalidated held
   responsibility, to a current server-returned hub recipient, with a plain
   evidence reference. The version is a positive decimal journal sequence, not
   the parcel's opaque hex version.
4. Persist the original account/API-scoped UUID and exact body before dispatch.
   Share ordinary-work mutual exclusion with duty/parcel commands; preserve all
   existing journal variants. On uncertain response, reconcile the original
   command before an explicit same-key retry. Restart/logout never substitutes
   a new recipient, amount, reference or key for the unresolved intent.
5. A saved offer means **Awaiting hub receipt**. It does not reduce held cash,
   increase remitted cash or imply buyer completion, reconciliation or earnings.
   The hub's separately authenticated receipt changes balances and may record
   a signed discrepancy. No native receive/reconcile/payout controls are added.
6. Handle unavailable capability, denied/hidden resources, stale review, request
   cooldown, late pages and account/API/access changes. Clear volatile financial
   facts and review input on background/covered routes, then revalidate on return.
   Keep pending protected commands recoverable without exposing another account.

`CASH_WRITES_VERIFIED` defaults to false, independently of earlier feature gates.
Read-only cash browsing remains usable when offers are disabled. Local tests do
not activate it or change the user's private map/build configuration.

See [testing](TESTING.md), [verification](VERIFICATION.md), and the
[API acceptance checklist](../../api/CASH_REMITTANCE_NEEDS.md). The existing
[Wallet retained-evidence requests](../../api/PREPAID_DELIVERY_NEEDS.md) remain
open and separate from cash implementation.
