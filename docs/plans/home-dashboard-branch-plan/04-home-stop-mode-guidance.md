# HDB-04 — Add focused Stop Mode and current-stop guidance

State: **planned, not activated**. Branch: `feat/home-stop-mode-guidance`.
Planning effort: **5–8 client hours**, including selected checks,
excluding owner/API/device waiting. Recommended model/effort: **GPT-6.1 Sol / Medium**.
Re-estimate from current evidence before activation; assign a 1–14 inclusive-day
window ending by November 20. No runtime result is claimed by this brief.

## Dependencies and API needs

- [HDB-03](03-home-dashboard-overview.md) merged and its relevant acceptance evidence available.

- [API-H01](../../api/HOME_DASHBOARD_NEEDS.md#api-h01) — use checked source evidence; satisfy unchecked live rows only when this branch needs live acceptance.
- [API-H06](../../api/HOME_DASHBOARD_NEEDS.md#api-h06) — use checked source evidence; satisfy unchecked live rows only when this branch needs live acceptance.

Backlog coverage references: [M04.07](../../backlog/M04.md#m04-07), [M06.05](../../backlog/M06.md#m06-05), [M07.02](../../backlog/M07.md#m07-02), [M09.01](../../backlog/M09.md#m09-01), [M09.02](../../backlog/M09.md#m09-02), [M09.03](../../backlog/M09.md#m09-03), [M09.04](../../backlog/M09.md#m09-04), [M09.05](../../backlog/M09.md#m09-05).
These are associations, not blanket completion of those cards. Consult the
[prerequisite audit](PREREQUISITES.md) for partial coverage versus later full-card
verification. Read direct and transitive prerequisites at activation; inherited
M01 contract, M02 transport/UI, M03 fresh access and relevant M16/privacy/device
gates remain mandatory. Unsupported release/recovery/earnings portions stay open.

## Scope

- Open a focused Work this stop view with full tracking/order identifier, friendly stage, recorded custody, current address and next responsible actor.
- Add explicit address/identifier copy, authorized call, fresh external directions and the existing Navigate/Stop controls.
- Show supplied buyer stop.instructions as plain Doorstep Guide text; seller/hub instructions remain absent unless the backend supplies them.
- Available pickups stay previews with no private contact/navigation; physical-work actions remain unavailable until their consumer branch is accepted.
- Use a conceptual seller-to-origin-hub or destination-hub-to-buyer leg guide without inventing an unsupplied next stop address or completed event.

## File ownership

- `lib/features/home/presentation/tasks_page.dart`
- `lib/features/home/presentation/home_task_panel.dart`
- `lib/features/navigation/presentation/navigation_controls.dart`
- `lib/features/home/data/operations_models.dart`
- proposed: focused Stop Mode presentation under lib/features/home/presentation/

Names marked proposed do not exist by implication. Inspect the actual current
architecture before choosing new files or moving a shared interface. Keep one
owner for journal/transport/DTO/controller changes and preserve Settings. Website
code/docs, its branch and unrelated work remain read only for this mobile slice.

## Finish evidence

- [ ] Current stop changes after confirmed collection/departure; old destination/phone/notes cannot remain actionable.
- [ ] Missing coordinates/address/contact/instructions, failed external launcher, unavailable map and unknown vehicle remain honest.
- [ ] Returning from directions, scanner/camera or app resume revalidates ownership and permissions.
- [ ] Copy/call/message controls are labelled and at least 48 logical pixels; focus, Back, keyboard and 200% text work.
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
