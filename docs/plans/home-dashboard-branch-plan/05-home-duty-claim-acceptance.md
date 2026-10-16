# HDB-05 — Accept one live duty and pickup-claim workflow

State: **native and website checks passed; local build profile activated**.
Branch: `feat/home-duty-claim-acceptance`.
See [the native results and website verification boundary](HDB-05-EVIDENCE.md).
The approved native Linux read and controlled duty/claim checks passed against
the owner-verified deployment, including replay, retained-intent recovery and
stale/changed-body rejection. The website's fresh 20/20 post-check matches the
commands and single assignment. The accepted local build profile enables duty
and claims; unconfigured builds and handover writes remain disabled by default.
Planning effort: **3–6 client hours**, including selected checks,
excluding owner/API/device waiting. Recommended model/effort: **GPT-6.1 Sol / High**.
Re-estimate from current evidence before activation; assign a 1–14 inclusive-day
window ending by November 20. Dated results live in the linked evidence.

## Dependencies and API needs

- [HDB-01](01-home-read-recovery.md) merged and its relevant acceptance evidence available.

- [API-H01](../../api/HOME_DASHBOARD_NEEDS.md#api-h01) — use checked source evidence; satisfy unchecked live rows only when this branch needs live acceptance.
- [API-H02](../../api/HOME_DASHBOARD_NEEDS.md#api-h02) — use checked source evidence; satisfy unchecked live rows only when this branch needs live acceptance.
- [API-H03](../../api/HOME_DASHBOARD_NEEDS.md#api-h03) — use checked source evidence; satisfy unchecked live rows only when this branch needs live acceptance.
- [API-H04](../../api/HOME_DASHBOARD_NEEDS.md#api-h04) — use checked source evidence; satisfy unchecked live rows only when this branch needs live acceptance.

Backlog coverage references: [M01.04](../../backlog/M01.md#m01-04), [M01.05](../../backlog/M01.md#m01-05), [M01.06](../../backlog/M01.md#m01-06), [M01.11](../../backlog/M01.md#m01-11), [M03.06](../../backlog/M03.md#m03-06), [M04.11](../../backlog/M04.md#m04-11), [M05.03](../../backlog/M05.md#m05-03), [M05.04](../../backlog/M05.md#m05-04), [M05.05](../../backlog/M05.md#m05-05), [M05.08](../../backlog/M05.md#m05-08), [M06.02](../../backlog/M06.md#m06-02), [M06.03](../../backlog/M06.md#m06-03), [M06.04](../../backlog/M06.md#m06-04), [M16.10](../../backlog/M16.md#m16-10).
These are associations, not blanket completion of those cards. Consult the
[prerequisite audit](PREREQUISITES.md) for partial coverage versus later full-card
verification. Read direct and transitive prerequisites at activation; inherited
M01 contract, M02 transport/UI, M03 fresh access and relevant M16/privacy/device
gates remain mandatory. Unsupported release/recovery/earnings portions stay open.

## Scope

- Reuse existing operational DTOs, durable duty/claim journal and native account transport; do not create another claim API.
- Obtain the owner’s dated deployed revision/migrations and approved isolated actor/parcel evidence before live operational writes.
- Verify fresh abilities/Home/queues/owned detail, then desired duty, one atomic claim, original-key replay and native-to-website assignment parity.
- Only after accepted evidence adjust the approved build’s operational-write activation; keep missing capabilities/placement/capacity enforced.
- If the gate is unmet, finish precise evidence/handoff and leave operational acceptance and activation open; do not replace it with sample success.

## File ownership

- `lib/features/home/data/operations_repository.dart`
- `lib/features/home/data/command_journal.dart`
- `lib/features/workspace/presentation/workspace_controller.dart`
- `lib/app/config.dart`
- `docs/plans/home-dashboard-navigation/SETUP_AND_ACCEPTANCE.md`
- `integration_test/ (selected native operational acceptance adapter, if needed)`

Names marked proposed do not exist by implication. Inspect the actual current
architecture before choosing new files or moving a shared interface. Keep one
owner for journal/transport/DTO/controller changes and preserve Settings. Website
code/docs, its branch and unrelated work remain read only for this mobile slice.

## Finish evidence

- [x] Explicit duty is replayable and off-duty preserves existing work.
- [x] Stale claim is rejected; uncertain response reconciles the persisted original UUID/body.
- [x] Claim opens fresh owned detail and is observed as assignment on the owning website, not collection.
- [x] Review and record ordinary-build write activation after the fresh website result.
- [x] No secret/config key, operational actor credentials or real personal parcel data enter tests, logs or Git.
- [x] Run analysis and the meaningful selected contract/controller/widget checks;
  add ordinary native builds when runtime/platform/integration risk requires them.
- [x] Record local versus authorized Azure versus physical Android evidence,
  remaining gates, reviewed source and coherent local commits in the owning plan.
- [x] Review scope/privacy and the staged diff; the user handles push/PR/merge.

The selected isolated case uses one designated rider. Simultaneous competing
actors remain an unchecked broader API acceptance item; the observed stale and
same-intent checks establish the selected single-rider workflow only. Physical
Android and later parcel/cash actions remain in their selected deliveries.

## Stop boundary

Finish only this selected delivery. Do not implement the next HDB/OPS branch,
change backend data/approval/custody to satisfy a fixture, add fake live success
or weaken a missing capability. If a required gate is absent, complete useful
local preparation and a precise handoff, leaving that acceptance unchecked.

Follow [the workflow](WORKFLOW.md), [blueprint](DASHBOARD.md),
[review](REVIEW.md) and [acceptance matrix](ACCEPTANCE.md). A later review fix
continues this branch; the next implementation begins from merged, updated main.
