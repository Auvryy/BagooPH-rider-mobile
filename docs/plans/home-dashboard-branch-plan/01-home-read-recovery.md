# HDB-01 — Recover reads and remove newly hidden tasks

State: **planned, not activated**. Branch: `fix/home-read-recovery`.
Planning effort: **4–7 client hours**, including selected checks,
excluding owner/API/device waiting. Recommended model/effort: **GPT-6.1 Sol / High**.
Re-estimate from current evidence before activation; assign a 1–14 inclusive-day
window ending by November 20. No runtime result is claimed by this brief.

## Dependencies and API needs

- Current approved mobile foundation, the accepted operations source and current account/Settings behavior.

- No new API contract required for this slice. Existing authorization and source/deployment limits still apply.

Backlog coverage references: [M04.06](../../backlog/M04.md#m04-06), [M04.07](../../backlog/M04.md#m04-07), [M04.09](../../backlog/M04.md#m04-09), [M04.10](../../backlog/M04.md#m04-10), [M04.11](../../backlog/M04.md#m04-11), [M04.12](../../backlog/M04.md#m04-12), [M16.04](../../backlog/M16.md#m16-04).
These are associations, not blanket completion of those cards. Consult the
[prerequisite audit](PREREQUISITES.md) for partial coverage versus later full-card
verification. Read direct and transitive prerequisites at activation; inherited
M01 contract, M02 transport/UI, M03 fresh access and relevant M16/privacy/device
gates remain mandatory. Unsupported release/recovery/earnings portions stay open.

## Scope

- Fix BUG-H01: distinguish recoverable read failures from unresolved command failures, and clear only the recovered read error after accepted fresh data.
- Fix BUG-H02: apply the same selected-task 404 invalidation during refresh as direct open; remove its cached row/pin, signal known authorization loss and stop its route immediately, independently of map readiness or Home visibility.
- Retain stale-data labels and pending UUID intents through network errors; 401/403 continue the existing session/access cleanup.
- Keep generation guards and honest first-page/load-more failure states; explain that search currently covers loaded rows.

## File ownership

- `lib/features/workspace/presentation/workspace_controller.dart`
- `lib/features/home/presentation/work_summary.dart`
- `lib/features/home/presentation/home_task_panel.dart`
- `lib/features/home/presentation/home_dashboard.dart`
- `lib/features/navigation/presentation/navigation_controller.dart`
- `lib/features/navigation/presentation/navigation_providers.dart`

Names marked proposed do not exist by implication. Inspect the actual current
architecture before choosing new files or moving a shared interface. Keep one
owner for journal/transport/DTO/controller changes and preserve Settings. Website
code/docs, its branch and unrelated work remain read only for this mobile slice.

## Finish evidence

- [ ] Failed Home read followed by accepted success removes the obsolete read error; an unresolved write stays unresolved.
- [ ] Queue read followed by selected-detail 404 removes the task/pin and stops navigation before its next periodic authorization check, including hidden Home and a keyboard-constrained view without a mounted map.
- [ ] Late queue/detail replies cannot restore hidden/private state; first page, failed append and explicit queue choice still work.
- [ ] Run analysis and the meaningful selected contract/controller/widget checks;
  add ordinary native builds when runtime/platform/integration risk requires them.
- [ ] Record local versus authorized Azure versus physical Android evidence,
  remaining gates, reviewed source and coherent local commits in the owning plan.
- [ ] Review scope/privacy and the staged diff; the user handles push/PR/merge.

## Stop boundary

Finish only this selected delivery. Do not implement the next HDB/OPS branch,
change backend data/approval/custody to satisfy a fixture, add fake live success
or weaken a missing capability. If a required gate is absent, complete useful
local preparation and a precise handoff, leaving that acceptance unchecked.

Follow [the workflow](WORKFLOW.md), [blueprint](DASHBOARD.md),
[review](REVIEW.md) and [acceptance matrix](ACCEPTANCE.md). A later review fix
continues this branch; the next implementation begins from merged, updated main.
