# HDB-07 — Scan and confirm seller collection, then await hub intake

State: **planned, not activated**. Branch: `feat/pickup-waybill-collection`.
Planning effort: **6–10 client hours**, including selected checks,
excluding owner/API/device waiting. Recommended model/effort: **GPT-6.1 Sol / High**.
Re-estimate from current evidence before activation; assign a 1–14 inclusive-day
window ending by November 20. No runtime result is claimed by this brief.

## Dependencies and API needs

- [HDB-04](04-home-stop-mode-guidance.md) merged and its relevant acceptance evidence available.
- [HDB-06](06-rider-shared-command-intents.md) merged and its relevant acceptance evidence available.

- [API-H02](../../api/HOME_DASHBOARD_NEEDS.md#api-h02) — use checked source evidence; satisfy unchecked live rows only when this branch needs live acceptance.
- [API-H03](../../api/HOME_DASHBOARD_NEEDS.md#api-h03) — use checked source evidence; satisfy unchecked live rows only when this branch needs live acceptance.
- [API-H05](../../api/HOME_DASHBOARD_NEEDS.md#api-h05) — use checked source evidence; satisfy unchecked live rows only when this branch needs live acceptance.

Backlog coverage references: [M06.01](../../backlog/M06.md#m06-01), [M06.05](../../backlog/M06.md#m06-05), [M06.06](../../backlog/M06.md#m06-06), [M06.07](../../backlog/M06.md#m06-07), [M06.08](../../backlog/M06.md#m06-08), [M06.09](../../backlog/M06.md#m06-09), [M06.12](../../backlog/M06.md#m06-12), [M16.05](../../backlog/M16.md#m16-05).
These are associations, not blanket completion of those cards. Consult the
[prerequisite audit](PREREQUISITES.md) for partial coverage versus later full-card
verification. Read direct and transitive prerequisites at activation; inherited
M01 contract, M02 transport/UI, M03 fresh access and relevant M16/privacy/device
gates remain mandatory. Unsupported release/recovery/earnings portions stay open.

## Scope

- Select a real Android scanner adapter at activation after checking primary documentation, SDK/platform support and license; no library/version is assumed by this plan.
- Implement actual scan capture, review and POST pickup for an owned pickup task with fresh version and actual barcode.
- After committed collection show the server origin-hub stop and Awaiting hub intake; only the hub handler records inbound custody.
- Optional submitted pickup notes follow the accepted command body; no independent client-generated chat/history success.
- Do not add claim release, direct seller-to-buyer delivery or rider-owned hub intake.

## File ownership

- `lib/features/home/data/operations_models.dart`
- `lib/features/home/data/operations_repository.dart`
- `lib/features/home/presentation/tasks_page.dart`
- proposed: scanner and pickup workflow feature adapters
- `pubspec.yaml and Android configuration only for the selected scanner`

Names marked proposed do not exist by implication. Inspect the actual current
architecture before choosing new files or moving a shared interface. Keep one
owner for journal/transport/DTO/controller changes and preserve Settings. Website
code/docs, its branch and unrelated work remain read only for this mobile slice.

## Finish evidence

- [ ] Real camera permission/cancel, unreadable/wrong barcode and matching scan are tested on a physical phone.
- [ ] No stored tracking number is passed as fabricated scan evidence.
- [ ] One collection/replay, lost response and stale/reassigned task preserve the original intent and correct custody.
- [ ] Actual origin-hub receipt ends pickup responsibility through its owning workflow and refreshes Home.
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
