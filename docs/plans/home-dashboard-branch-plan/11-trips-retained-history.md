# HDB-11 — Connect real Trips, protected evidence and recent Home work

State: **planned, not activated**. Branch: `feat/trips-retained-history`.
Planning effort: **5–9 client hours**, including selected checks,
excluding owner/API/device waiting. Recommended model/effort: **GPT-6.1 Sol / High**.
Re-estimate from current evidence before activation; assign a 1–14 inclusive-day
window ending by November 20. No runtime result is claimed by this brief.

## Dependencies and API needs

- [HDB-06](06-rider-shared-command-intents.md) merged and its relevant acceptance evidence available.
- [HDB-09](09-final-mile-cod-handoff.md) merged and its relevant acceptance evidence available.
- [HDB-10](10-failed-delivery-return-guidance.md) merged and its relevant acceptance evidence available.

- [API-H03](../../api/HOME_DASHBOARD_NEEDS.md#api-h03) — use checked source evidence; satisfy unchecked live rows only when this branch needs live acceptance.
- [API-H05](../../api/HOME_DASHBOARD_NEEDS.md#api-h05) — use checked source evidence; satisfy unchecked live rows only when this branch needs live acceptance.

Backlog coverage references: [M11.01](../../backlog/M11.md#m11-01), [M11.02](../../backlog/M11.md#m11-02), [M11.03](../../backlog/M11.md#m11-03), [M11.04](../../backlog/M11.md#m11-04), [M11.05](../../backlog/M11.md#m11-05), [M11.06](../../backlog/M11.md#m11-06), [M11.07](../../backlog/M11.md#m11-07), [M11.08](../../backlog/M11.md#m11-08), [M11.09](../../backlog/M11.md#m11-09), [M11.10](../../backlog/M11.md#m11-10).
These are associations, not blanket completion of those cards. Consult the
[prerequisite audit](PREREQUISITES.md) for partial coverage versus later full-card
verification. Read direct and transitive prerequisites at activation; inherited
M01 contract, M02 transport/UI, M03 fresh access and relevant M16/privacy/device
gates remain mandatory. Unsupported release/recovery/earnings portions stay open.

## Scope

- Replace unavailable live history with typed retained-assignment Trips, server filters/pagination, detail and protected checkpoint/attempt proof.
- Preserve trip assignment identity, original outcome/recipient/collection and current parcel state as distinct facts after reassignment.
- Align search with the current tracking/order query; Manila filters use assignment dates, not an invented delivery-day total.
- Add a small Latest recorded work Home section using actual returned records and a labelled link to full Trips.
- No Delivered today total/chart or earnings is inferred from a limited page or assignment date.

## File ownership

- `lib/features/trips/presentation/trips_page.dart`
- `lib/features/workspace/data/workspace_models.dart`
- `lib/features/workspace/data/workspace_repository.dart`
- `selected live Trips/private-evidence adapters`
- `lib/features/home/presentation/home_dashboard.dart`

Names marked proposed do not exist by implication. Inspect the actual current
architecture before choosing new files or moving a shared interface. Keep one
owner for journal/transport/DTO/controller changes and preserve Settings. Website
code/docs, its branch and unrelated work remain read only for this mobile slice.

## Finish evidence

- [ ] Foreign trip/child and changed/missing proof are denied; bearer/private bytes never use cross-origin redirects/public shortcuts.
- [ ] Original attribution survives reassignment, null legacy facts remain absent and original outcome differs from current state.
- [ ] Date boundaries, server pagination/deduplication, search/copy and refresh after terminal task disappearance work.
- [ ] Home recent records state their loaded scope and do not imply complete daily aggregates.
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
