# HDB-15 — Submit a remittance offer without claiming recipient receipt

State: **planned, not activated**. Branch: `feat/rider-cash-remittance-offers`.
Planning effort: **4–7 client hours**, including selected checks,
excluding owner/API/device waiting. Recommended model/effort: **GPT-6.1 Sol / High**.
Re-estimate from current evidence before activation; assign a 1–14 inclusive-day
window ending by November 20. No runtime result is claimed by this brief.

## Dependencies and API needs

- [HDB-06](06-rider-shared-command-intents.md) merged and its relevant acceptance evidence available.
- [HDB-14](14-home-cash-responsibilities.md) merged and its relevant acceptance evidence available.

- [API-H03](../../api/HOME_DASHBOARD_NEEDS.md#api-h03) — use checked source evidence; satisfy unchecked live rows only when this branch needs live acceptance.
- [API-H04](../../api/HOME_DASHBOARD_NEEDS.md#api-h04) — use checked source evidence; satisfy unchecked live rows only when this branch needs live acceptance.
- [API-H08](../../api/HOME_DASHBOARD_NEEDS.md#api-h08) — use checked source evidence; satisfy unchecked live rows only when this branch needs live acceptance.

Backlog coverage references: [M15.05](../../backlog/M15.md#m15-05), [M15.06](../../backlog/M15.md#m15-06), [M15.07](../../backlog/M15.md#m15-07), [M15.08](../../backlog/M15.md#m15-08), [M15.10](../../backlog/M15.md#m15-10), [M15.11](../../backlog/M15.md#m15-11).
These are associations, not blanket completion of those cards. Consult the
[prerequisite audit](PREREQUISITES.md) for partial coverage versus later full-card
verification. Read direct and transitive prerequisites at activation; inherited
M01 contract, M02 transport/UI, M03 fresh access and relevant M16/privacy/device
gates remain mandatory. Unsupported release/recovery/earnings portions stay open.

## Scope

- Offer to a returned permitted hub recipient using journal-sequence expected_version, exact peso amount and evidence reference.
- Persist/reconcile the original offer; success is awaiting_recipient_receipt.
- Refresh responsibility/history after a separately recorded hub receipt; the rider cannot receive or reconcile.
- Keep network/version/recipient/amount rejection actionable and preserve unknown command results.
- No banking transfer, payout, withdrawal or new earnings writer.

## File ownership

- `selected cash offer controller/form and live adapter`
- `shared typed command journal`
- `selected Home cash/detail refresh`

Names marked proposed do not exist by implication. Inspect the actual current
architecture before choosing new files or moving a shared interface. Keep one
owner for journal/transport/DTO/controller changes and preserve Settings. Website
code/docs, its branch and unrelated work remain read only for this mobile slice.

## Finish evidence

- [ ] Wrong recipient/version/amount, expiry/conflict, lost response and same-key retry cannot duplicate an offer.
- [ ] Offer does not change held/remitted facts before real hub receipt.
- [ ] Actual native offer, hub receipt and website journal agree under authorized isolated cash data.
- [ ] Physical amount/reference input, resume and account cleanup are accepted.
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
