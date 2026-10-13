# HDB-09 — Record genuine proof, recipient and exact COD delivery

State: **planned, not activated**. Branch: `feat/final-mile-cod-handoff`.
Planning effort: **7–12 client hours**, including selected checks,
excluding owner/API/device waiting. Recommended model/effort: **GPT-6.1 Sol / High**.
Re-estimate from current evidence before activation; assign a 1–14 inclusive-day
window ending by November 20. No runtime result is claimed by this brief.

## Dependencies and API needs

- [HDB-06](06-rider-shared-command-intents.md) merged and its relevant acceptance evidence available.
- [HDB-08](08-final-mile-scanned-departure.md) merged and its relevant acceptance evidence available.

- [API-H03](../../api/HOME_DASHBOARD_NEEDS.md#api-h03) — use checked source evidence; satisfy unchecked live rows only when this branch needs live acceptance.
- [API-H05](../../api/HOME_DASHBOARD_NEEDS.md#api-h05) — use checked source evidence; satisfy unchecked live rows only when this branch needs live acceptance.

Backlog coverage references: [M07.05](../../backlog/M07.md#m07-05), [M07.06](../../backlog/M07.md#m07-06), [M07.07](../../backlog/M07.md#m07-07), [M07.08](../../backlog/M07.md#m07-08), [M07.09](../../backlog/M07.md#m07-09), [M07.10](../../backlog/M07.md#m07-10), [M07.11](../../backlog/M07.md#m07-11), [M07.12](../../backlog/M07.md#m07-12), [M07.13](../../backlog/M07.md#m07-13), [M07.14](../../backlog/M07.md#m07-14), [M07.15](../../backlog/M07.md#m07-15).
These are associations, not blanket completion of those cards. Consult the
[prerequisite audit](PREREQUISITES.md) for partial coverage versus later full-card
verification. Read direct and transitive prerequisites at activation; inherited
M01 contract, M02 transport/UI, M03 fresh access and relevant M16/privacy/device
gates remain mandatory. Unsupported release/recovery/earnings portions stay open.

## Scope

- Implement recipient relationship/name, actual proof capture/selection and exact cash received/change/confirmation for a permitted COD task.
- Use multipart deliver with original bytes and accepted field names; respect 5,242,880-byte genuine JPEG/PNG/WebP validation.
- Show committed/reconciled result and receipt facts; an upload or GPS proximity never claims success.
- Close active task/navigation after accepted outcome and expose a truthful recorded-work/history entry when available.
- Keep prepaid handoff unavailable until a separately approved backend outcome contract exists; buyer completion and remittance remain separate.

## File ownership

- `selected proof adapter and protected command storage`
- `lib/features/home/data/operations_repository.dart`
- `lib/features/home/presentation/tasks_page.dart`
- `selected delivery/recipient/cash form controllers`

Names marked proposed do not exist by implication. Inspect the actual current
architecture before choosing new files or moving a shared interface. Keep one
owner for journal/transport/DTO/controller changes and preserve Settings. Website
code/docs, its branch and unrelated work remain read only for this mobile slice.

## Finish evidence

- [ ] Proof permission/cancel/replacement, process interruption and original-byte replay are verified on Android.
- [ ] Exact large cent/peso values, incorrect cash/change, missing proof/recipient and rejected stale versions cannot deliver.
- [ ] Success, lost response, transaction/storage failure and duplicate replay do not add another collection/checkpoint.
- [ ] Native delivered record agrees with hub/buyer/cash records while buyer COMPLETED and hub remittance remain untouched.
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
