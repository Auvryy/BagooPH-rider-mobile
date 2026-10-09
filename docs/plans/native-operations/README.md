# Native Rider operations integration plan

Reviewed October 9, 2026. **Planning only: no batch is activated by this document.**
The backend handoff is complete in source; Flutter operational integration and
Azure/Android acceptance remain separate work. Existing account, Settings and
mobile visual behavior are preserved.

## Starting evidence

- Mobile starts from `a59ca5b`, which includes the merged presentation work.
- Backend checkout is clean `main` at `1d785aa`. Its operations contract,
  OpenAPI, example register, native plan and routes were reviewed read only.
- The executable spec describes 25 operations, version `1.0.0`; discovery uses
  `operations_api_version: 1`. See [source review](SOURCE_REVIEW.md).
- The current app still selects `UnavailableWorkspaceRepository` for operations.
  Having styled pages or backend source does not establish a live consumer.
- Azure revision, migrations, fresh operational bearer and physical Android
  behavior have **not** been verified in this documentation task.

## Five batches from the handoff

| Plan ID | Batch | Existing backlog association | State |
|---|---|---|---|
| OPS-01 | [Home, duty, pickup claims and owned tasks](01-home-duty-pickups.md) | M04, M05, M06.01–M06.04 | Planned |
| OPS-02 | [Real scan, pickup, departure, delivery/COD and failure](02-scan-parcel-work.md) | M06–M08, selected M09 dependencies | Planned |
| OPS-03 | [Trips and authenticated private proof](03-trips-private-proof.md) | M11 | Planned |
| OPS-04 | [Assignment-bound messages and notifications](04-messages-notifications.md) | M10, M12 | Planned |
| OPS-05 | [Cash records and remittance offers](05-cash-remittance.md) | M15 | Planned |

Use that sequence as the default. Each batch can be split into smaller selected
read, write and acceptance slices; it is not a promise to fit a whole batch in
one branch or day. Existing backend effort ranges are not Flutter estimates.
Do not change the 180-card catalog, its statuses or the presentation deadline
merely because this handoff is available.

Before coding, read [deployment acceptance](DEPLOYMENT_GATE.md) and
[shared consumer rules](CONSUMER_RULES.md), then inspect the chosen backlog cards
and **all transitive prerequisites**. M01 contract compatibility, M02 transport,
M03 fresh-session/access handling and the relevant M16 checks remain dependencies.
Current implementation can supply evidence without treating every old planned
card as automatically complete.

## Plan ownership and boundaries

This directory owns the handoff-specific Flutter sequence, decisions and batch
acceptance evidence. The [registry](../README.md) owns plan discovery;
[API coordination](../../api/INTEGRATION_PLAN.md) owns cross-repository workflow;
[task tracking](../../TASK_TRACKING.md) owns major areas. The backend owns routes,
wire schemas, custody, assignment, money and current deployment audit.

Change only the selected batch file for its progress. Shared consumer rules and
transport need an agreed single change owner when batches overlap. Record scope
changes here; do not overwrite another plan or duplicate its canonical contract.

Native release, restricted recovery and earnings remain disabled. No final-mile
self-assignment, rider-owned hub intake, buyer order completion, bank transfer,
payout, live GPS/ETA, new push provider or offline-success queue enters this plan.
Conditional backend batch 6 and future features require separate selection.

For every later implementation, record the reviewed/deployed revision, changed
Flutter files and local commits, actual analysis/tests, native API/cross-role
checks, Android checks and precise remaining blockers. Mock success never clears
an operational acceptance gate.
