# HDB-13 — Connect phase-bound Messages and the current-stop shortcut

State: **planned, not activated**. Branch: `feat/rider-assignment-messages`.
Planning effort: **6–10 client hours**, including selected checks,
excluding owner/API/device waiting. Recommended model/effort: **GPT-6.1 Sol / High**.
Re-estimate from current evidence before activation; assign a 1–14 inclusive-day
window ending by November 20. No runtime result is claimed by this brief.

## Dependencies and API needs

- [HDB-04](04-home-stop-mode-guidance.md) merged and its relevant acceptance evidence available.
- [HDB-06](06-rider-shared-command-intents.md) merged and its relevant acceptance evidence available.
- [HDB-12](12-home-durable-notices.md) merged and its relevant acceptance evidence available.

- [API-H03](../../api/HOME_DASHBOARD_NEEDS.md#api-h03) — use checked source evidence; satisfy unchecked live rows only when this branch needs live acceptance.
- [API-H07](../../api/HOME_DASHBOARD_NEEDS.md#api-h07) — use checked source evidence; satisfy unchecked live rows only when this branch needs live acceptance.

Backlog coverage references: [M10.01](../../backlog/M10.md#m10-01), [M10.02](../../backlog/M10.md#m10-02), [M10.03](../../backlog/M10.md#m10-03), [M10.04](../../backlog/M10.md#m10-04), [M10.05](../../backlog/M10.md#m10-05), [M10.06](../../backlog/M10.md#m10-06), [M10.07](../../backlog/M10.md#m10-07), [M10.08](../../backlog/M10.md#m10-08), [M10.09](../../backlog/M10.md#m10-09), [M10.10](../../backlog/M10.md#m10-10), [M10.11](../../backlog/M10.md#m10-11), [M10.12](../../backlog/M10.md#m10-12).
These are associations, not blanket completion of those cards. Consult the
[prerequisite audit](PREREQUISITES.md) for partial coverage versus later full-card
verification. Read direct and transitive prerequisites at activation; inherited
M01 contract, M02 transport/UI, M03 fresh access and relevant M16/privacy/device
gates remain mandatory. Unsupported release/recovery/earnings portions stay open.

## Scope

- Connect existing conversation/message APIs to the current Messages UI using exact phase/assignment/participant thread IDs.
- Add Message from an owned current stop only after resolving the authorized thread and current can_send.
- Retain drafts in their original thread/participant scope and persist send/read intent; never silently move a draft after reassignment.
- Acknowledge only the selected rendered incoming message boundary and pause background/offstage acknowledgements.
- Home shows a communication shortcut; do not label a sum from one conversation page as a global unread count.

## File ownership

- `lib/features/messages/presentation/messages_page.dart`
- `lib/features/workspace/presentation/workspace_controller.dart`
- `lib/features/workspace/data/workspace_repository.dart`
- `selected live message/thread models and adapter`
- `selected Stop Mode/Home shortcut`

Names marked proposed do not exist by implication. Inspect the actual current
architecture before choosing new files or moving a shared interface. Keep one
owner for journal/transport/DTO/controller changes and preserve Settings. Website
code/docs, its branch and unrelated work remain read only for this mobile slice.

## Finish evidence

- [ ] Seller pickup versus buyer final-mile participant, stale/foreign/read-only thread, duplicate send and same-key recovery work.
- [ ] New unseen messages stay unread; obsolete rendered boundaries cannot acknowledge another thread.
- [ ] Physical Android keyboard, Back, background/resume and private draft cleanup remain usable.
- [ ] Any global unread-chat badge waits for an authoritative aggregate or is explicitly labelled as loaded-chat scope.
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
