# Remaining backend acceptance for native delivery

Read-only source review on November 1, 2026 at web `f001d39`. The numbered
source findings below were resolved in the later Bagoo branch and merged by
PR #144. This remains an API-owner handoff for deployment and live acceptance.

1. In `RiderTripService`, resolve a Wallet handoff's original recipient from the
   immutable `WalletHandoverReceipt` matched to the retained delivered checkpoint,
   delivery and original actor. Do not fall back to the order's editable recipient.
2. In `checkpointProof`, obtain the Wallet receipt's original proof hash for the
   same owned actor/checkpoint. Preserve assignment ownership, safe private path,
   hash mismatch rejection and no-store headers. The unconditional `CodAccount`
   lookup still rejects valid Wallet proof, because Wallet creates no COD account.
3. Add owner regressions for original Wallet recipient/proof, changed order
   recipient, later assignment, foreign actor, missing/mismatched receipt,
   altered/missing image, exact replay and unchanged COD/attempt-proof behavior.
4. Update the handover API test around `RiderHandoverApiTest:234`: its prepared
   version-two order now correctly reaches `completed`. Assert the order's actual
   version and applicable original payment/earnings evidence. Retain explicit
   older-version confirmation coverage; do not weaken automatic completion to
   restore an obsolete expectation.
5. Remove unconditional buyer-confirmation copy from `RiderTaskService` in the
   owning response. The native client now handles the known old sentence while
   preserving actual recovery instructions, but other consumers need accurate
   source text too.

Re-run the existing [prepaid consumer acceptance](../../api/PREPAID_DELIVERY_NEEDS.md)
against the fixed committed source and require original proof/recipient success,
rather than accepting the former diagnostic 404 as a passing acceptance case.
Reconfirm deployed revision, migrations, fresh native abilities and designated
owned resources before enabling writes. Duty/claim acceptance is independent.

The prior focused backend run at this revision had 295 passes and one old
completion expectation failure, using isolated SQLite in the configured PHP
container. That result is a dated source baseline, not a new passing backend
suite or evidence about deployment.

## November 1 source follow-up

The five source items above were addressed on Bagoo branch
`fix/rider-wallet-trip-evidence` through
`9e58312d130809eb8cd878189b729f1f702291d8`. The focused backend suite then
passed 452 tests and 16,115 assertions, including original receipt matching,
proof integrity, foreign denial, reassignment and version-two handover status.
The Rider's native prepaid integration test also passed against that pinned
revision, verifying exact retained proof bytes and recipient after replay.

This owner handoff is closed for source changes, and PR #144 merged them into
Bagoo `main` at `9ca5db5`. It remains open for confirming deployment and
migrations, fresh Azure discovery, controlled owned-resource acceptance,
independent buyer/hub/earnings outcomes and physical Android verification.
Write gates remain unchanged.
