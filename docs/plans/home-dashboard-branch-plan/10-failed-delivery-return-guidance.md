# HDB-10 — Record one failed attempt and show hub-owned recovery

State: **planned, not activated**. Branch: `feat/failed-delivery-return-guidance`.
Planning effort: **5–8 client hours**, including selected checks,
excluding owner/API/device waiting. Recommended model/effort: **GPT-6.1 Sol / High**.
Re-estimate from current evidence before activation; assign a 1–14 inclusive-day
window ending by November 20. No runtime result is claimed by this brief.

## Dependencies and API needs

- [HDB-06](06-rider-shared-command-intents.md) merged and its relevant acceptance evidence available.
- [HDB-08](08-final-mile-scanned-departure.md) merged and its relevant acceptance evidence available.
- [HDB-09](09-final-mile-cod-handoff.md) merged and its relevant acceptance evidence available.

- [API-H03](../../api/HOME_DASHBOARD_NEEDS.md#api-h03) — use checked source evidence; satisfy unchecked live rows only when this branch needs live acceptance.
- [API-H05](../../api/HOME_DASHBOARD_NEEDS.md#api-h05) — use checked source evidence; satisfy unchecked live rows only when this branch needs live acceptance.

Backlog coverage references: [M08.01](../../backlog/M08.md#m08-01), [M08.02](../../backlog/M08.md#m08-02), [M08.03](../../backlog/M08.md#m08-03), [M08.04](../../backlog/M08.md#m08-04), [M08.05](../../backlog/M08.md#m08-05), [M08.06](../../backlog/M08.md#m08-06), [M08.07](../../backlog/M08.md#m08-07), [M08.08](../../backlog/M08.md#m08-08), [M08.12](../../backlog/M08.md#m08-12).
These are associations, not blanket completion of those cards. Consult the
[prerequisite audit](PREREQUISITES.md) for partial coverage versus later full-card
verification. Read direct and transitive prerequisites at activation; inherited
M01 contract, M02 transport/UI, M03 fresh access and relevant M16/privacy/device
gates remain mandatory. Unsupported release/recovery/earnings portions stay open.

## Scope

- Decode the supplied failure policy/reasons, attempt counts/limit and return hub; current Home DTO does not yet consume this full policy.
- Submit fail with actual scan, allowed reason, required notes/location and genuine original proof bytes.
- Show return responsibility until destination-hub receipt; display later hub-approved retry/RTS decisions from returned records.
- Reconcile original failure intent after uncertainty; never decrement attempts or independently reschedule/reassign.
- Native restricted recovery remains unavailable; provide the documented owning workflow instead of privileged rider commands.

## File ownership

- `lib/features/home/data/operations_models.dart`
- `lib/features/home/data/operations_repository.dart`
- `selected failure/evidence form and Stop Mode presentation`

Names marked proposed do not exist by implication. Inspect the actual current
architecture before choosing new files or moving a shared interface. Keep one
owner for journal/transport/DTO/controller changes and preserve Settings. Website
code/docs, its branch and unrelated work remain read only for this mobile slice.

## Finish evidence

- [ ] Wrong reason, missing notes/location/proof, stale task and duplicate intent cannot create another attempt.
- [ ] Return custody remains with rider until authenticated hub receipt.
- [ ] Attempt one/two retry and third-failure RTS guidance use actual owner evidence and do not give the rider approval authority.
- [ ] Restriction/account change clears private views and stops navigation without inventing native recovery permission.
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
