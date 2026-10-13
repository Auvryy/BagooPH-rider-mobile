# HDB-14 — Add exact cash responsibility and recorded receipt views

State: **planned, not activated**. Branch: `feat/home-cash-responsibilities`.
Planning effort: **4–7 client hours**, including selected checks,
excluding owner/API/device waiting. Recommended model/effort: **GPT-6.1 Sol / High**.
Re-estimate from current evidence before activation; assign a 1–14 inclusive-day
window ending by November 20. No runtime result is claimed by this brief.

## Dependencies and API needs

- [HDB-03](03-home-dashboard-overview.md) merged and its relevant acceptance evidence available.
- [HDB-06](06-rider-shared-command-intents.md) merged and its relevant acceptance evidence available.
- [HDB-11](11-trips-retained-history.md) merged and its relevant acceptance evidence available.

- [API-H03](../../api/HOME_DASHBOARD_NEEDS.md#api-h03) — use checked source evidence; satisfy unchecked live rows only when this branch needs live acceptance.
- [API-H08](../../api/HOME_DASHBOARD_NEEDS.md#api-h08) — use checked source evidence; satisfy unchecked live rows only when this branch needs live acceptance.

Backlog coverage references: [M15.01](../../backlog/M15.md#m15-01), [M15.02](../../backlog/M15.md#m15-02), [M15.03](../../backlog/M15.md#m15-03), [M15.04](../../backlog/M15.md#m15-04), [M15.05](../../backlog/M15.md#m15-05), [M15.06](../../backlog/M15.md#m15-06), [M15.07](../../backlog/M15.md#m15-07), [M15.08](../../backlog/M15.md#m15-08), [M15.10](../../backlog/M15.md#m15-10), [M15.11](../../backlog/M15.md#m15-11).
These are associations, not blanket completion of those cards. Consult the
[prerequisite audit](PREREQUISITES.md) for partial coverage versus later full-card
verification. Read direct and transitive prerequisites at activation; inherited
M01 contract, M02 transport/UI, M03 fresh access and relevant M16/privacy/device
gates remain mandatory. Unsupported release/recovery/earnings portions stay open.

## Scope

- Consume existing cash list/detail and the all-owned-journals summary for a compact Home responsibility card and secondary detail view.
- Keep own held, actually remitted, pending offer, discrepancy, excess and reconciliation separate with exact cents.
- Show actual authorized recipient/instructions without giving rider receipt, adjustment or reconciliation permissions.
- Retain Tasks/Trips/Messages/Profile as the four main destinations; cash is a supported Home/detail entry, not a speculative fifth tab.
- Keep unavailable earnings null and labelled; COD/shipping/commission are not rider income.

## File ownership

- proposed: cash models/repository/controller/views
- `lib/features/home/presentation/home_dashboard.dart`
- `shared exact-money formatting and authenticated transport`

Names marked proposed do not exist by implication. Inspect the actual current
architecture before choosing new files or moving a shared interface. Keep one
owner for journal/transport/DTO/controller changes and preserve Settings. Website
code/docs, its branch and unrelated work remain read only for this mobile slice.

## Finish evidence

- [ ] Large/signed amounts, zero versus unknown, pending/discrepant/reconciled journals and off-duty retained cash are correct.
- [ ] Summary basis is all owned journals, independent of q/page; it is not a sum of the visible page.
- [ ] Foreign account/access loss and original receipt attribution preserve privacy.
- [ ] Home displays a cash card only from accepted returned cash data, without earnings guesses.
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
