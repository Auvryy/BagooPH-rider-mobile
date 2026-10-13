# HDB-06 — Extend durable command/proof foundation for later actions

State: **planned, not activated**. Branch: `feat/rider-shared-command-intents`.
Planning effort: **6–10 client hours**, including selected checks,
excluding owner/API/device waiting. Recommended model/effort: **GPT-6.1 Sol / High**.
Re-estimate from current evidence before activation; assign a 1–14 inclusive-day
window ending by November 20. No runtime result is claimed by this brief.

## Dependencies and API needs

- [HDB-05](05-home-duty-claim-acceptance.md) merged and its relevant acceptance evidence available.

- [API-H04](../../api/HOME_DASHBOARD_NEEDS.md#api-h04) — use checked source evidence; satisfy unchecked live rows only when this branch needs live acceptance.
- [API-H05](../../api/HOME_DASHBOARD_NEEDS.md#api-h05) — use checked source evidence; satisfy unchecked live rows only when this branch needs live acceptance.

Backlog coverage references: [M01.06](../../backlog/M01.md#m01-06), [M01.07](../../backlog/M01.md#m01-07), [M01.08](../../backlog/M01.md#m01-08), [M01.09](../../backlog/M01.md#m01-09), [M02.07](../../backlog/M02.md#m02-07), [M02.08](../../backlog/M02.md#m02-08), [M02.09](../../backlog/M02.md#m02-09), [M16.02](../../backlog/M16.md#m16-02), [M16.03](../../backlog/M16.md#m16-03), [M16.04](../../backlog/M16.md#m16-04).
These are associations, not blanket completion of those cards. Consult the
[prerequisite audit](PREREQUISITES.md) for partial coverage versus later full-card
verification. Read direct and transitive prerequisites at activation; inherited
M01 contract, M02 transport/UI, M03 fresh access and relevant M16/privacy/device
gates remain mandatory. Unsupported release/recovery/earnings portions stay open.

## Scope

- Extend the current journal, which accepts only duty/claim, into explicit typed selected command variants for parcel, message/read, notice/read and cash offer.
- Agree protected retention and cleanup for unresolved metadata and original proof bytes before implementing private storage.
- Preserve existing duty/claim records and account/API isolation across upgrade, restart, reauthentication and logout.
- Support multipart original-file fingerprints, accepted result types, version differences and expired/unknown reconciliation without a generic status writer.
- Keep a single unresolved intent boundary and exact same-key/body/file retry; never silently recapture, compress or change recipient/amount.

## File ownership

- `lib/features/home/data/command_journal.dart`
- `lib/features/home/data/operations_repository.dart`
- `lib/core/network/rider_api_client.dart`
- proposed: shared command and private proof adapters under lib/core/

Names marked proposed do not exist by implication. Inspect the actual current
architecture before choosing new files or moving a shared interface. Keep one
owner for journal/transport/DTO/controller changes and preserve Settings. Website
code/docs, its branch and unrelated work remain read only for this mobile slice.

## Finish evidence

- [ ] Existing stored duty/claim can still reconcile after upgrade; unsupported stored variants are handled without silent deletion.
- [ ] Persist-before-dispatch, interrupted upload, original-byte hash/retention, same-key replay, conflict and expiry are verified.
- [ ] Cash journal sequence versions are distinct from parcel hex versions; money/IDs never use floats.
- [ ] Account change/access loss clears visible private state without exposing or discarding another actor’s unresolved recovery evidence.
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
