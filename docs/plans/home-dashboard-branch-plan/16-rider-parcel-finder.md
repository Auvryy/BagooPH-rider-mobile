# HDB-16 — Add selected personal parcel-slot labels

State: **planned, not activated**. Branch: `feat/rider-parcel-finder`.
Planning effort: **3–5 client hours**, including selected checks,
excluding owner/API/device waiting. Recommended model/effort: **GPT-6.1 Sol / Medium**.
Re-estimate from current evidence before activation; assign a 1–14 inclusive-day
window ending by November 20. No runtime result is claimed by this brief.

## Dependencies and API needs

- [HDB-04](04-home-stop-mode-guidance.md) merged and its relevant acceptance evidence available.
- [HDB-07](07-pickup-waybill-collection.md) merged and its relevant acceptance evidence available.

- No new API contract required for this slice. Existing authorization and source/deployment limits still apply.

Backlog coverage references: [M04.06](../../backlog/M04.md#m04-06), [M06.06](../../backlog/M06.md#m06-06), [M06.07](../../backlog/M06.md#m06-07), [M16.02](../../backlog/M16.md#m16-02), [M16.04](../../backlog/M16.md#m16-04).
These are associations, not blanket completion of those cards. Consult the
[prerequisite audit](PREREQUISITES.md) for partial coverage versus later full-card
verification. Read direct and transitive prerequisites at activation; inherited
M01 contract, M02 transport/UI, M03 fresh access and relevant M16/privacy/device
gates remain mandatory. Unsupported release/recovery/earnings portions stay open.

## Scope

- Implement the already selected Parcel Finder as personal organization for owned pickup parcels and a single supported final-mile parcel.
- Proposed first scope is session-only labels keyed by API/account/task plus authoritative assignment reference; decide this explicitly at activation.
- Show full identifier, distinguishing suffix and an unset slot state; more than one parcel may share a slot.
- Clear labels on logout, denied access, assignment change and terminal responsibility; editing a label never records scan/custody.
- Persistent or server-synchronized labels require a separately selected retention/contract scope; no multi-stop dispatch change.

## File ownership

- proposed: session-scoped Parcel Finder state/view
- `selected Stop Mode/task selection presentation`

Names marked proposed do not exist by implication. Inspect the actual current
architecture before choosing new files or moving a shared interface. Keep one
owner for journal/transport/DTO/controller changes and preserve Settings. Website
code/docs, its branch and unrelated work remain read only for this mobile slice.

## Finish evidence

- [ ] Two parcels/same slot, refreshed task, changed assignment, logout/account change and terminal removal keep tags correctly scoped.
- [ ] Preview/unverified ownership cannot create a misleading held-parcel label.
- [ ] Wrong scan remains a rejected scan regardless of the label/suffix.
- [ ] No backend mutation, location history or cross-account persisted label is introduced by the session-only scope.
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
