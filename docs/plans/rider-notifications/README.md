# Rider Notifications inbox

Selected October 19, 2026 on `feat/home-durable-notices`, from merged Rider main
`cc3a65f` (Parcel Finder PR 28). This package owns the selected
[HDB-12](../home-dashboard-branch-plan/12-home-durable-notices.md) inbox and notice
portion of [OPS-04](../native-operations/04-messages-notifications.md).
It associates with [M12](../../backlog/M12.md); it does not complete all nine
cards or replace the five-batch operations plan.

## Source and prerequisites

Read-only website source: `b476f44aecf1c78aeaccd914d3c5456874ad9436`.
Reviewed native routes, operations contract/OpenAPI, `RiderNotificationController`,
`NotificationCenterService`, durable delivery/lifecycle/governance/COD services,
command retention, native contract/connected/boundary tests and current roadmap.
Another maintainer's unrelated buyer changes remain untouched. This is source
evidence; it does not establish Azure's revision or scheduler configuration.
The later native kernel snapshots `c590ae2a9491020cd1266399b4ad304b888b71df`;
the selected native route/controller/service/contract diff from the initial
review is empty. Its source is distinct from deployment evidence.
Final read-only review at `3f7691e8a7eda28196d5ded351c464abbe5d0c3f`
found an additional `buyer-return` notice type and browser read-snapshot helpers.
Native routes, DTOs, exact displayed-ID acknowledgement and command retention are
unchanged. The client already accepts unknown notice types and ignores
unsupported destinations; the browser helpers are not called by this client.

The selected Home overview, first-party session/transport, durable commands,
owned Stop Mode and Trips foundations are in merged main. Their wider outcome,
Azure and physical-device gates remain independent. HDB-06 and HDB-11 briefs
retain historical full-scope planning; the implementations in the
[order/delivery/Trips package](../rider-orders-delivery-trips/README.md) supply the
needed foundations. The canonical HDB-12 closure (49 associated/prerequisite
cards) was reviewed: M01 contract/authority, M02 UI/transport, M03 fresh session,
M04 owned resources and M16.02 cleanup apply here. Recovery, cash offers and
other unselected prerequisites are not implicitly implemented.

## Selected behavior

- Home exposes a labelled Notifications entry and the server's all-owned
  `unread_count`, independent of loaded page size.
- A bounded lazy inbox loads 20 rows per page, deduplicates offset overlaps and
  retains at most 200 loaded notices. Refresh starts again at page one.
- Plain-text detail preserves unknown event types, missing text and unsupported
  destinations. Selecting a notice does not acknowledge it.
- Explicit single read and **Mark visible as read** use exact displayed UUIDs.
  Viewport measurement excludes cached/offscreen rows; refresh invalidates the
  rendered snapshot. No timestamp cutoff or global mark-all is used.
- A separate account/API-scoped secure journal persists the original read UUID
  and canonical IDs before dispatch. Recovery reads the retained result first;
  an unknown result permits only explicit same-intent retry within seven days.
  Work and Messages journals retain their original keys and isolation.
- Task links fetch current owned detail and enter existing Stop Mode. Cash and
  account links fetch exact authorized native records and show read-only facts.
  Relative hrefs must match an allowlist; no returned href is launched or fetched
  directly. Company/future/null/malformed targets stay readable without a link.
- Workspace owns foreground/resume polling and the existing request budget.
  Background/account/access changes cancel reads and clear visible private state.
  Linked record views recheck after resume; no background notification loop runs.

New read writes use the independent default-false
`NOTIFICATIONS_WRITES_VERIFIED` deployment switch. Browsing uses actual server
data when Home advertises the capability. This adds no provider key, dependency,
platform permission, push service, backend change, cash writer or operational
transition. Existing account, map, duty/claim and parcel/Message gates stay intact.

## Work and acceptance

Client estimate: **6 hours**, October 19–25 inclusive, excluding external waiting.
Measured effort remains separate. Implement contract/journal, controller, inbox
and Home entry, then verify local/native behavior and ordinary builds.

See [TESTING.md](TESTING.md), [VERIFICATION.md](VERIFICATION.md) and the
[API checklist](../../api/NOTIFICATIONS_NEEDS.md). Local results cannot clear
Azure delivery/cross-role or physical Android acceptance. The user handles push
and merge; this branch never changes the website checkout or production records.

The selected client is locally verified: **45 notification checks**, **539 full
suite passes with four expected skips**, clean analysis, a passing isolated
native Laravel check and ordinary Linux/Android debug builds. The
[native check](LOCAL_KERNEL.md) and external gates remain separately documented.
