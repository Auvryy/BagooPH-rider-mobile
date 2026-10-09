# OPS-01 — Home, duty, pickup claims and owned tasks

State: **planned, not activated**. Prerequisites: [deployment gate](DEPLOYMENT_GATE.md),
[consumer foundation](CONSUMER_RULES.md), current account access and selected
M01/M02/M03/M16 evidence. Backlog associations: B04-A–B04-D, B05-A–B05-C and
B06-A; inspect the exact cards and their transitive dependencies before selecting.

## Contract and implementation slices

Use GET `rider/home`, `rider/pickup-jobs`, `rider/tasks` and `rider/tasks/{task}`;
PATCH `rider/duty`; POST `rider/pickup-jobs/{job}/claim`; and command reconciliation.
The task list requires `phase=pickup` or `final_mile`. Do not substitute proposed
`tasks/available` routes or a generic status setter.

1. Add exact operational models/version/capability discovery and authorized reads
   through the shared transport. Map wire resources into the existing workspace
   interfaces deliberately; retain unavailable later features rather than fixtures.
2. Connect existing Home/header/filters/detail/pagination to real resources. Home
   owns placement, eligibility, returned capacity/counts and duty; no guessed hub
   or hardcoded active-pickup limit. Available previews stay seller-only.
3. Add explicit desired duty and an atomic pickup claim with durable/reconciled
   intent. Refetch owned detail after assignment and refresh Home/queues after duty.
   Claim is assignment, not seller pickup or origin-hub receipt.
4. Preserve existing work when off duty. Final-mile is hub-assigned; there is no
   client self-assignment. Act only on returned permissions and fresh versions.

Primary file area: existing Home/workspace data/controller/pages. Shared session,
transport or journal edits need a single change owner; do not rewrite Settings.
Suggested branches are separate read and write slices, not one all-feature branch.

## Finish evidence

- Analysis and meaningful DTO/transport/controller/layout tests pass; owner
  success/empty/denied/stale fixtures match current wire shapes.
- Fresh Azure Home/queues/detail return the approved actor's actual scope.
  Empty/placement/capacity/old-token states stay truthful.
- Authorized duty/claim is observed through the native client and owning website;
  stale/losing claim cannot produce a second assignment. Timeout/restart keeps the
  original key and reconciles, including unknown or expired command behavior.
- On actual Android, login/session, refresh/resume, navigation and inputs work;
  changing account/access removes private views immediately.

No scan/outcome, hub intake, claim release or fixture success is included. Record
what was local, Azure and Android separately before claiming this batch complete.
