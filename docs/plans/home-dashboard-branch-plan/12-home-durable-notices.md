# HDB-12 — Add a real Home inbox and exact notice read state

State: **planned, not activated**. Branch: `feat/home-durable-notices`.
Planning effort: **4–7 client hours**, including selected checks,
excluding owner/API/device waiting. Recommended model/effort: **GPT-6.1 Sol / High**.
Re-estimate from current evidence before activation; assign a 1–14 inclusive-day
window ending by November 20. No runtime result is claimed by this brief.

## Dependencies and API needs

- [HDB-03](03-home-dashboard-overview.md) merged and its relevant acceptance evidence available.
- [HDB-06](06-rider-shared-command-intents.md) merged and its relevant acceptance evidence available.
- [HDB-11](11-trips-retained-history.md) merged and its relevant acceptance evidence available.

- [API-H01](../../api/HOME_DASHBOARD_NEEDS.md#api-h01) — use checked source evidence; satisfy unchecked live rows only when this branch needs live acceptance.
- [API-H03](../../api/HOME_DASHBOARD_NEEDS.md#api-h03) — use checked source evidence; satisfy unchecked live rows only when this branch needs live acceptance.
- [API-H07](../../api/HOME_DASHBOARD_NEEDS.md#api-h07) — use checked source evidence; satisfy unchecked live rows only when this branch needs live acceptance.

Backlog coverage references: [M12.01](../../backlog/M12.md#m12-01), [M12.02](../../backlog/M12.md#m12-02), [M12.03](../../backlog/M12.md#m12-03), [M12.04](../../backlog/M12.md#m12-04), [M12.05](../../backlog/M12.md#m12-05), [M12.06](../../backlog/M12.md#m12-06), [M12.07](../../backlog/M12.md#m12-07), [M12.08](../../backlog/M12.md#m12-08), [M12.09](../../backlog/M12.md#m12-09).
These are associations, not blanket completion of those cards. Consult the
[prerequisite audit](PREREQUISITES.md) for partial coverage versus later full-card
verification. Read direct and transitive prerequisites at activation; inherited
M01 contract, M02 transport/UI, M03 fresh access and relevant M16/privacy/device
gates remain mandatory. Unsupported release/recovery/earnings portions stay open.

## Scope

- Consume existing durable notification pages/unread_count and add a labelled Home entry plus a bounded inbox.
- Mark only displayed owned notice IDs through typed durable read commands; do not use a time cutoff.
- Resolve task/cash/account targets through fresh authorization; null/stale/unknown targets remain readable.
- Share foreground/resume polling and native request budget; verify the deployed notification scheduler.
- Do not add a new push provider, websocket or client-generated system notice.

## File ownership

- proposed: native notification models/repository/controller/views
- `lib/features/home/presentation/home_dashboard.dart`
- `lib/features/workspace/presentation/workspace_shell.dart`
- `shared command/refresh foundation`

Names marked proposed do not exist by implication. Inspect the actual current
architecture before choosing new files or moving a shared interface. Keep one
owner for journal/transport/DTO/controller changes and preserve Settings. Website
code/docs, its branch and unrelated work remain read only for this mobile slice.

## Finish evidence

- [ ] Owned one-read/exact displayed list, new arrival during read, duplicate/uncertain command and foreign ID rejection work.
- [ ] Unread badge comes from server aggregate rather than loaded-page size.
- [ ] Changed/null/unknown destinations cannot open stale private task/cash data.
- [ ] Actual backend delivery and Android foreground/Back/account cleanup are recorded separately from mocks.
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
