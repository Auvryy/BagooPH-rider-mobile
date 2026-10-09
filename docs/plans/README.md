# Scoped implementation plans

This registry keeps each plan in its own directory. It supplements the project
roadmap and backlog; it does not replace their scope, stable IDs or deadlines.

| Plan | Scope | State | Entry |
|---|---|---|---|
| Native operations | Consume the completed backend Rider API in five Flutter batches | Planned; Azure/device acceptance outstanding | [Plan](native-operations/README.md) |

## Rules for future plans

1. Choose one stable descriptive slug and create `docs/plans/<slug>/README.md`.
   Keep that plan's steps, source review, decisions and evidence in its directory.
   Add one registry row and one discovery link; do not rewrite another plan.
2. State the objective, exclusions, authoritative sources, reviewed revisions,
   dependencies, intended source files, acceptance checks and current status.
   Distinguish source implementation, deployment and device evidence.
3. Link the canonical [task map](../TASK_TRACKING.md),
   [backlog](../SUBTASK_BACKLOG.md) and [source rules](../SOURCES.md).
   Reference their IDs; do not create a competing backlog or silently change them.
4. Split large plans into named batches. A plan-specific ID such as `OPS-01`
   is distinct from a backlog batch such as `B04-A`. Creating a plan does not
   activate its batches or create all their external work records.
5. Each batch owns its document and implementation slice. Coordinate any shared
   transport, model or controller edit before concurrent implementation. Separate
   document folders reduce collisions; they do not eliminate source merge conflicts.
6. Keep API schemas owned by the backend, visual tokens owned by the design docs,
   and delivery commitments owned by [the delivery plan](../DELIVERY_PLAN.md).
   Record an agreed change once at its owner and link it from affected plans.
7. On activation, recheck transitive prerequisites and evidence, re-estimate the
   chosen slice and use a 1–14 inclusive-day window ending by November 20.
   The user handles publication. Copyable AI prompts stay outside the repository.

A completed planning document is not a completed feature. Future evidence updates
belong in the selected plan/batch; shared indexes contain only short pointers.
