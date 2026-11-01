# Cash & Remittance verification

Selected October 22, 2026 from Rider main `a371e2e`; backend committed source
`89ad0b923e38af459d3d59be993c140af63b3e5b`. Website work is concurrent and
read-only to this mobile task. Source compatibility, deployed acceptance and
physical Android evidence are separate.

## November 1 version-two compatibility follow-up

- Rider commit `41f0fda` on `fix/rider-workflow-recovery` updates the cash
  integration assertions for the current version-two contract and parses
  backend rider-shift UUIDs instead of treating shift IDs as numeric. The
  focused financial contract and summary tests passed (**8 tests**).
- The headless cash-page widget file passed (**7 tests**), including the
  pending-offer website handoff: it opens the fixed first-party `/cod` page
  without account query parameters or a native POST. This verifies the Rider
  handoff only; the website cancellation action still needs deployed acceptance.
- The reviewed Bagoo checkout's `main` and `origin/main` are at `f001d39`.
  The pushed source branch `fix/rider-wallet-trip-evidence` is at `9e58312`,
  two commits ahead of that main snapshot. Its default version-two delivery
  records the order as `completed`/`paid`; COD remains held until a separate
  hub receipt, and unreleased delivery earnings remain pending.
- The isolated COD native scenario was pointed at immutable Bagoo revision
  `9e58312` and stopped before a test result was produced after the user asked
  not to interact with the desktop. The new assertions are committed, but
  this run does **not** accept the native COD/hub-receipt scenario. No Azure
  cash action or physical Android check was performed.

## Local implementation verified — October 22, 2026

- `flutter analyze --no-pub`: no issues.
- `flutter test --no-pub --reporter expanded`: **638 passed, five expected
  skips**, exit 0. This includes 33 new cash cases covering exact signed amounts,
  original command recovery, denied/stale access, pagination, guarded session
  routes, synchronous draft clearing and explicit Manila dates.
- Ordinary configured Linux debug and Android debug APK builds: both exit 0.
  These retain the real account entrypoint; fixtures never replace login.
- Independent native Linux transport and secure-command test against the real
  Laravel kernel: passed against immutable backend snapshot
  `43558b3cbc53c4449704d6647681b5444fad3f62`. The selected cash controller,
  services and executable API schema are unchanged from initial review
  `89ad0b923e38af459d3d59be993c140af63b3e5b`. Concurrent website edits were
  preserved; mobile made no backend changes.
- That scenario uses two genuine synthetic COD responsibilities and actual
  owning hub receipt actions. Exactly two offers survive pre-dispatch loss,
  post-commit loss and original replay after receipt. Offers leave balances
  unchanged. Two independent hub receipts match website journals, including a
  signed **−₱1.00** shortage and remaining **₱1.00** responsibility. Filtered
  lists preserve the all-owned summary; foreign access, stale versions and
  wrong recipients are denied. Buyer completion, platform reconciliation and
  earnings are not fabricated. Native execution took 129.4 seconds including
  compilation; the scenario itself took approximately 83 seconds.
- Headless real-font layout checks cover 320/390/840 logical widths and enlarged
  text. Independent screenshot review confirmed readable normal phone layouts,
  wrapping at enlarged text, and reachable ordinary scrolling. No desktop app
  window or physical Android claim is needed for these layout checks.

Review corrected signed event amounts, recovered-command wording after receipt,
account/API/approval route revocation, pagination races and explicit Manila
calendar boundaries. Final verification ran after those corrections. No new
package, API key or platform permission was introduced. Existing private map
configuration and earlier write gates are preserved.

## Acceptance still separate

- Actual Azure revision and command/cash source migrations, fresh native cash
  ability and actual Home capability.
- Designated isolated rider/hub responsibility and authorized counted-cash
  procedure; independent offer/receipt and journal comparison on that deployment.
- Physical Android financial input, lifecycle, interrupted-request recovery and
  account/privacy behavior.
- Confirmed earnings requires a separately selected backend contract; no income
  is inferred from COD, shipping or commission.

The [API checklist](../../api/CASH_REMITTANCE_NEEDS.md) keeps these requests
explicit. `CASH_WRITES_VERIFIED` remains default-false; earlier operational
acceptance and the existing private Geoapify configuration remain unchanged.
