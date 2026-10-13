# HDB-08 — Scan a hub-assigned parcel out for delivery

State: **planned, not activated**. Branch: `feat/final-mile-scanned-departure`.
Planning effort: **4–7 client hours**, including selected checks,
excluding owner/API/device waiting. Recommended model/effort: **GPT-6.1 Sol / High**.
Re-estimate from current evidence before activation; assign a 1–14 inclusive-day
window ending by November 20. No runtime result is claimed by this brief.

## Dependencies and API needs

- [HDB-04](04-home-stop-mode-guidance.md) merged and its relevant acceptance evidence available.
- [HDB-06](06-rider-shared-command-intents.md) merged and its relevant acceptance evidence available.
- [HDB-07](07-pickup-waybill-collection.md) merged and its relevant acceptance evidence available.

- [API-H02](../../api/HOME_DASHBOARD_NEEDS.md#api-h02) — use checked source evidence; satisfy unchecked live rows only when this branch needs live acceptance.
- [API-H03](../../api/HOME_DASHBOARD_NEEDS.md#api-h03) — use checked source evidence; satisfy unchecked live rows only when this branch needs live acceptance.
- [API-H05](../../api/HOME_DASHBOARD_NEEDS.md#api-h05) — use checked source evidence; satisfy unchecked live rows only when this branch needs live acceptance.

Backlog coverage references: [M07.01](../../backlog/M07.md#m07-01), [M07.02](../../backlog/M07.md#m07-02), [M07.03](../../backlog/M07.md#m07-03), [M07.04](../../backlog/M07.md#m07-04), [M07.05](../../backlog/M07.md#m07-05), [M16.05](../../backlog/M16.md#m16-05).
These are associations, not blanket completion of those cards. Consult the
[prerequisite audit](PREREQUISITES.md) for partial coverage versus later full-card
verification. Read direct and transitive prerequisites at activation; inherited
M01 contract, M02 transport/UI, M03 fresh access and relevant M16/privacy/device
gates remain mandatory. Unsupported release/recovery/earnings portions stay open.

## Scope

- Reuse the real scanner for a current final-mile task assigned by the destination hub.
- Submit actual scan/version to depart and reconcile its original command.
- Refresh the task from destination-hub collection to the frozen buyer destination; navigation to a changed stop requires explicit revalidation/restart.
- Render exact recorded COD and explicit unsupported/non-COD handoff state without a guessed zero amount.
- Keep hub assignment and Mother-Hub routing outside courier authority.

## File ownership

- `lib/features/home/data/operations_models.dart`
- `lib/features/home/data/operations_repository.dart`
- `lib/features/home/presentation/tasks_page.dart`
- `selected scanner/departure controller and Stop Mode`

Names marked proposed do not exist by implication. Inspect the actual current
architecture before choosing new files or moving a shared interface. Keep one
owner for journal/transport/DTO/controller changes and preserve Settings. Website
code/docs, its branch and unrelated work remain read only for this mobile slice.

## Finish evidence

- [ ] Unassigned/foreign/reassigned tasks and wrong scan cannot depart.
- [ ] One committed departure changes custody/current stop consistently on native app and hub records.
- [ ] Duplicate/uncertain submission keeps one intent; old hub route is stopped before buyer navigation.
- [ ] Physical scan/permission/restart coverage and off-duty owned work remain correct.
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
