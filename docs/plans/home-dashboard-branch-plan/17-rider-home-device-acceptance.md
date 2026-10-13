# HDB-17 — Accept the complete selected Home workflow on real devices

State: **planned, not activated**. Branch: `test/rider-home-device-acceptance`.
Planning effort: **6–10 client hours**, including selected checks,
excluding owner/API/device waiting. Recommended model/effort: **GPT-6.1 Sol / High**.
Re-estimate from current evidence before activation; assign a 1–14 inclusive-day
window ending by November 20. No runtime result is claimed by this brief.

## Dependencies and API needs

- [HDB-01](01-home-read-recovery.md) merged and its relevant acceptance evidence available.
- [HDB-02](02-home-navigation-lifecycle.md) merged and its relevant acceptance evidence available.
- [HDB-03](03-home-dashboard-overview.md) merged and its relevant acceptance evidence available.
- [HDB-04](04-home-stop-mode-guidance.md) merged and its relevant acceptance evidence available.
- [HDB-05](05-home-duty-claim-acceptance.md) merged and its relevant acceptance evidence available.
- [HDB-06](06-rider-shared-command-intents.md) merged and its relevant acceptance evidence available.
- [HDB-07](07-pickup-waybill-collection.md) merged and its relevant acceptance evidence available.
- [HDB-08](08-final-mile-scanned-departure.md) merged and its relevant acceptance evidence available.
- [HDB-09](09-final-mile-cod-handoff.md) merged and its relevant acceptance evidence available.
- [HDB-10](10-failed-delivery-return-guidance.md) merged and its relevant acceptance evidence available.
- [HDB-11](11-trips-retained-history.md) merged and its relevant acceptance evidence available.
- [HDB-12](12-home-durable-notices.md) merged and its relevant acceptance evidence available.
- [HDB-13](13-rider-assignment-messages.md) merged and its relevant acceptance evidence available.
- [HDB-14](14-home-cash-responsibilities.md) merged and its relevant acceptance evidence available.
- [HDB-15](15-rider-cash-remittance-offers.md) merged and its relevant acceptance evidence available.

- [API-H02](../../api/HOME_DASHBOARD_NEEDS.md#api-h02) — use checked source evidence; satisfy unchecked live rows only when this branch needs live acceptance.
- [API-H03](../../api/HOME_DASHBOARD_NEEDS.md#api-h03) — use checked source evidence; satisfy unchecked live rows only when this branch needs live acceptance.
- [API-H05](../../api/HOME_DASHBOARD_NEEDS.md#api-h05) — use checked source evidence; satisfy unchecked live rows only when this branch needs live acceptance.
- [API-H07](../../api/HOME_DASHBOARD_NEEDS.md#api-h07) — use checked source evidence; satisfy unchecked live rows only when this branch needs live acceptance.
- [API-H08](../../api/HOME_DASHBOARD_NEEDS.md#api-h08) — use checked source evidence; satisfy unchecked live rows only when this branch needs live acceptance.

Backlog coverage references: [M16.03](../../backlog/M16.md#m16-03), [M16.04](../../backlog/M16.md#m16-04), [M16.05](../../backlog/M16.md#m16-05), [M16.06](../../backlog/M16.md#m16-06), [M16.07](../../backlog/M16.md#m16-07), [M16.08](../../backlog/M16.md#m16-08), [M16.09](../../backlog/M16.md#m16-09), [M16.10](../../backlog/M16.md#m16-10), [M16.13](../../backlog/M16.md#m16-13).
These are associations, not blanket completion of those cards. Consult the
[prerequisite audit](PREREQUISITES.md) for partial coverage versus later full-card
verification. Read direct and transitive prerequisites at activation; inherited
M01 contract, M02 transport/UI, M03 fresh access and relevant M16/privacy/device
gates remain mandatory. Unsupported release/recovery/earnings portions stay open.

## Scope

- Use the selected acceptance matrix for current source, real Azure resources and a physical Android phone; execute only authorized owning-role workflows.
- Verify Home/Stop Mode, scanner/proof, original-key recovery, recorded history, chat/notices and exact cash from one coherent cross-role fixture.
- Verify actual GPS permissions, notifications, minimized/screen-off navigation, Stop, access loss, changed destination and force-stop/restart boundary.
- Review responsive/large-text/reduced-motion/keyboard/Back and private data cleanup; Linux remains a manual-origin/layout/native-network target.
- Record accepted, failed and unavailable scope honestly; optional Parcel Finder is included only if HDB-16 was selected.

## File ownership

- `integration_test/ selected Home/native/device acceptance`
- `selected meaningful feature regression tests`
- `docs/plans/home-dashboard-branch-plan/ACCEPTANCE.md`
- `owning selected feature evidence documents`

Names marked proposed do not exist by implication. Inspect the actual current
architecture before choosing new files or moving a shared interface. Keep one
owner for journal/transport/DTO/controller changes and preserve Settings. Website
code/docs, its branch and unrelated work remain read only for this mobile slice.

## Finish evidence

- [ ] Actual seller -> pickup -> origin hub -> Mother Hub -> destination hub -> rider -> buyer and cash receipt/reconciliation stay with their owning actors.
- [ ] Physical permission denial and background navigation evidence is distinct from widget mocks, Linux preview and APK compilation.
- [ ] Private request/proof headers, foreign/revoked resources, queued/expired/uncertain intents and account changes reject or reconcile correctly.
- [ ] Publish reproducible checks and precise remaining gaps without declaring unrelated major areas or release identity/signing complete.
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
