# HDB-03 — Make the Home overview useful with existing server data

State: **merged in PR 20; selected local checks verified**.
Branch: `feat/home-dashboard-overview`.
Activated October 14, 2026 from clean, updated `main` `d6ff936` after HDB-01,
HDB-02 and the Philippines map slice (PR 19) were merged. Point estimate:
**6 client hours**, October 14–16, due October 16 at 18:00 Asia/Manila.
See [selected implementation evidence](HDB-03-EVIDENCE.md).
Planning effort: **4–7 client hours**, including selected checks,
excluding owner/API/device waiting. Recommended model/effort: **GPT-6.1 Sol / Medium**.
The selected window is three inclusive calendar days and ends before November 20.
Local UI verification does not establish fresh Azure or physical-phone acceptance.

## Dependencies and API needs

- [HDB-01](01-home-read-recovery.md) merged and its relevant acceptance evidence available.
- [HDB-02](02-home-navigation-lifecycle.md) merged and its relevant acceptance evidence available.

- [API-H01](../../api/HOME_DASHBOARD_NEEDS.md#api-h01) — use checked source evidence; satisfy unchecked live rows only when this branch needs live acceptance.

Backlog coverage references: [M04.03](../../backlog/M04.md#m04-03), [M04.04](../../backlog/M04.md#m04-04), [M04.05](../../backlog/M04.md#m04-05), [M04.08](../../backlog/M04.md#m04-08), [M04.09](../../backlog/M04.md#m04-09), [M05.02](../../backlog/M05.md#m05-02), [M05.06](../../backlog/M05.md#m05-06).
These are associations, not blanket completion of those cards. Consult the
[prerequisite audit](PREREQUISITES.md) for partial coverage versus later full-card
verification. Read direct and transitive prerequisites at activation; inherited
M01 contract, M02 transport/UI, M03 fresh access and relevant M16/privacy/device
gates remain mandatory. Unsupported release/recovery/earnings portions stay open.

## Scope

- Implement the approved dashboard blueprint using the existing three queue counts, pickup capacity, actual company/hub and eligibility.
- Show checked time/freshness and one refresh action; preserve unknown versus zero, off-duty owned responsibilities and explicit queue selection.
- Fix BUG-H03 through shared friendly stage display in rows, selected summary and details; unfamiliar codes remain unknown without granting actions.
- Keep map-first mobile Home, one normal page scroll, bounded map and clear bottom-navigation space; bring task controls within practical reach at large text.
- Do not add daily-completion totals, charts, earnings, ETA or distance rankings from incomplete data.

## File ownership

- `lib/features/home/presentation/home_dashboard.dart`
- `lib/features/home/presentation/home_task_panel.dart`
- `lib/features/home/presentation/work_summary.dart`
- `lib/features/home/presentation/tasks_page.dart`
- `lib/features/workspace/presentation/workspace_widgets.dart`

Names marked proposed do not exist by implication. Inspect the actual current
architecture before choosing new files or moving a shared interface. Keep one
owner for journal/transport/DTO/controller changes and preserve Settings. Website
code/docs, its branch and unrelated work remain read only for this mobile slice.

## Finish evidence

- [x] 320/390/430/840/1000/1440 widths, 200% text and keyboard have reachable work filters/actions with no draggable task panel.
- [x] Loading, missing placement, empty, full capacity, read failure/stale recovery and unknown counts are distinct.
- [x] Details use a friendly current-stage label and full identifier; shared formatting never changes server permissions.
- [x] Dashboard quantities match returned counts/capacity and time comes from observed data.
- [x] Run analysis and the meaningful selected contract/controller/widget checks;
  add ordinary native builds when runtime/platform/integration risk requires them.
- [x] Record local versus authorized Azure versus physical Android evidence,
  remaining gates, reviewed source and coherent local commits in the owning plan.
- [x] Review scope/privacy and the staged diff; the user handles push/PR/merge.

## Stop boundary

Finish only this selected delivery. Do not implement the next HDB/OPS branch,
change backend data/approval/custody to satisfy a fixture, add fake live success
or weaken a missing capability. If a required gate is absent, complete useful
local preparation and a precise handoff, leaving that acceptance unchecked.

Follow [the workflow](WORKFLOW.md), [blueprint](DASHBOARD.md),
[review](REVIEW.md) and [acceptance matrix](ACCEPTANCE.md). A later review fix
continues this branch; the next implementation begins from merged, updated main.
