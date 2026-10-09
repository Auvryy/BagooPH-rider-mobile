# OPS-03 — Trips and authenticated private evidence

State: **planned, not activated**. Needs current shared/session/privacy foundation,
retained authorized assignments and outcome evidence from the preceding slices.
Associations: B11-A–B11-C; respect M11's transitive M07/private-proof dependencies.

## Contract and implementation slices

GET `rider/trips`, `rider/trips/{trip}` and the checkpoint/attempt `/proof` reads.
Trip IDs are `trip-<original assignment checkpoint ID>`, distinct from phase-task
references. History must not inherit a later rider's assignment or outcome.

1. Decode owned history, attribution, original outcome, current state, checkpoints
   and attempts. Use bounded pages, plain search, phase/payment filters and stable
   deduplication. Unknown/null legacy facts remain absent rather than guessed.
2. Inclusive from/to date filters mean Asia/Manila **assignment-recorded** dates;
   timestamps are UTC. Payment/COD collection is not earnings or remittance.
3. Fetch relative private proof URLs through the same-origin bearer transport.
   Reject cross-origin redirects/public storage shortcuts, verify permitted binary
   type and respect no-store/privacy headers. Handle hidden/missing proof and
   `EVIDENCE_CHANGED`; clear private view/cache on access or account changes.

Primary ownership: existing Trips data/views and a purpose-scoped private evidence
loader. Account/lifecycle/transport edits are shared foundation changes, not a new
trip-only token store or another complete schema copy.

## Finish evidence

- Consumer/date/pagination/privacy tests distinguish original assignment from
  current state, ambiguous legacy facts and missing/changed proof.
- Azure and actual Android show only authorized original history and private
  image bytes. Foreign trip/child and removed/restricted authority are denied.
- Original recipient/collection/stop facts survive permitted reassignment; neither
  a later rider's outcome nor public historical POD is used as owned proof.
- Successful outcomes and resume refresh history; app/account changes remove
  private evidence promptly. Report source, Azure and device evidence separately.
