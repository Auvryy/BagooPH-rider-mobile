# HDB-02 — Stop ended location streams and bound hidden map work

State: **planned, not activated**. Branch: `fix/home-navigation-lifecycle`.
Planning effort: **4–7 client hours**, including selected checks,
excluding owner/API/device waiting. Recommended model/effort: **GPT-6.1 Sol / High**.
Re-estimate from current evidence before activation; assign a 1–14 inclusive-day
window ending by November 20. No runtime result is claimed by this brief.

## Dependencies and API needs

- [HDB-01](01-home-read-recovery.md) merged and its relevant acceptance evidence available.

- No new API contract required for this slice. Existing authorization and source/deployment limits still apply.

Backlog coverage references: [M09.06](../../backlog/M09.md#m09-06), [M09.07](../../backlog/M09.md#m09-07), [M09.08](../../backlog/M09.md#m09-08), [M16.04](../../backlog/M16.md#m16-04), [M16.06](../../backlog/M16.md#m16-06).
These are associations, not blanket completion of those cards. Consult the
[prerequisite audit](PREREQUISITES.md) for partial coverage versus later full-card
verification. Read direct and transitive prerequisites at activation; inherited
M01 contract, M02 transport/UI, M03 fresh access and relevant M16/privacy/device
gates remain mandatory. Unsupported release/recovery/earnings portions stay open.

## Scope

- Fix BUG-H04: a location stream ending without an error must stop/clear navigation and explain how to restart; late callbacks from an old stream must be ignored.
- Fix BUG-H05: recognize the registered Sedan / Van alias as the driving profile;
  preserve registered-profile precedence and explicit unknown-vehicle choice.
- Add explicit Home visibility/foreground handling for map painting, tile requests and camera updates; keep the persistent rider-started navigation controller independent.
- Preserve panning/Recenter behavior, correct vehicle precedence, original GPS/accuracy/rerouting limits and provider/bearer isolation.
- Keep map errors and attribution readable in small/keyboard views; add a bounded retry after provider cooldown without inventing tiles or roads.

## File ownership

- `lib/features/navigation/presentation/navigation_controller.dart`
- `lib/features/navigation/presentation/navigation_controls.dart`
- `lib/features/home/presentation/home_dashboard.dart`
- `lib/features/workspace/presentation/workspace_shell.dart`
- `lib/features/navigation/presentation/geoapify_tiles.dart`
- `lib/features/navigation/data/route_geometry.dart`

Names marked proposed do not exist by implication. Inspect the actual current
architecture before choosing new files or moving a shared interface. Keep one
owner for journal/transport/DTO/controller changes and preserve Settings. Website
code/docs, its branch and unrelated work remain read only for this mobile slice.

## Finish evidence

- [ ] Normal stream completion, stream error, Stop and permission removal each end the active navigation state once.
- [ ] The registered Sedan / Van value selects driving without an unnecessary
  unknown-vehicle error; unsupported values are not silently forced to driving.
- [ ] Home offstage causes no new view-driven tile/camera churn while active navigation authorization/fixes continue.
- [ ] Return to Home, keyboard/rotation and map pan/Recenter preserve explicit following mode; quota and missing coordinates retain text fallback.
- [ ] A paused state exposes its reason and explicit revalidation path even when
  Home/the map is hidden. Revalidation never auto-starts tracking.
- [ ] Physical Android minimized/screen-off continuation remains a separate acceptance item, not a mock-test claim.
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
