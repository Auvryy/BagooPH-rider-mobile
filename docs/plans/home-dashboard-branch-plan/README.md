# Home dashboard review and branch plan

Reviewed October 13, 2026. The original planning delivery changed documentation.
The user subsequently activated **HDB-01**, plus the Settings touch/large-text
correction; see [its implementation evidence](HDB-01-EVIDENCE.md).
The user selects one future branch per
implementation prompt, reviews it, publishes and merges it, then starts the next
branch from updated `main`.

Mobile baseline: `e04a2536987eaf31cf1e6760207dba1da80d9258`. Initial backend reference:
`0571f75d10cac0dc9f7da9875e4d801fdc941bdc`; a later read observed
`10619cea9fac27a642533e401180f6a618f72158` on the other developer's
`fix/registration-contact-uniqueness` branch with ongoing uncommitted work.
The final source check observed clean backend `main` at
`b91f13a57c7fedbd0252b0d98eeefe834b160aee` after the owner's merge; core Home/API
fingerprints stayed unchanged. None of those website changes were made here.
The [review](REVIEW.md) distinguishes the
committed source, observed work in progress, confirmed defects, UI improvements
and unknown live/device behavior. Recheck both checkouts when activating a branch.

## Read in this order

| Document | Purpose |
|---|---|
| [Review and bug inventory](REVIEW.md) | Every Home surface, actual findings, source evidence and verification limits |
| [Dashboard blueprint](DASHBOARD.md) | What to add, where it belongs and which returned data supports it |
| [Branch sequence](BRANCHES.md) | One bounded delivery at a time, with dependencies, ownership and effort |
| [Prerequisite audit](PREREQUISITES.md) | Full canonical dependencies versus the selected partial implementation/acceptance scope |
| [Git and prompt workflow](WORKFLOW.md) | Implement, review, user push/merge, pull `main`, then new branch |
| [Acceptance matrix](ACCEPTANCE.md) | Local, Azure, cross-role and physical-device finish evidence |
| [HDB-02 evidence](HDB-02-EVIDENCE.md) | Navigation stream/revalidation, hidden map work and provider loading checks |
| [HDB-03 evidence](HDB-03-EVIDENCE.md) | Actual Home overview, observed freshness and shared task-stage display |
| [HDB-04 evidence](HDB-04-EVIDENCE.md) | Focused current-stop detail, fresh contact/directions and lifecycle safeguards |
| [HDB-05 evidence](HDB-05-EVIDENCE.md) | Native Azure read baseline, prepared operations adapter and deferred duty/claim acceptance |
| [Future PH map focus](PH_MAP_FOCUS_NEXT.md) | Country-shaped display, current-stop framing and map-quality recommendations |
| [Separate Home API checklist](../../api/HOME_DASHBOARD_NEEDS.md) | Existing server capabilities, required verification and conditional requests |
| [Account compatibility watch](ACCOUNT_COMPATIBILITY.md) | Changed account contracts and a separate conditional follow-up outside Home bug fixes |

The individual branch documents are technical implementation briefs. They carry
enough context to survive a fresh conversation; each implementation still reads
current instructions, source and dependency evidence first.

## Start here

**HDB-01, `fix/home-read-recovery`, is the recommended first implementation.**
It handles a recoverable error that stays visible after success and a refresh-time
hidden task that can retain its cached pin and active route. HDB-02 then fixes
location-stream completion, the registered Sedan / Van mapping and map/view
lifecycle behavior. Both can be
implemented against isolated tests without activating production writes.

HDB-03/HDB-04 improve the overview and focused stop experience using existing
data. HDB-05 is the separate live duty/claim acceptance gate. Scanning, physical
outcomes and connected records follow their explicit dependencies. Backend
coordinate extensions are not prerequisites for address-first UI or pickup claims.

## Scope and existing owners

This plan supplements [Home dashboard/navigation](../home-dashboard-navigation/README.md)
and the [five native API batches](../native-operations/README.md). It references
[M04–M16 and the task map](../../TASK_TRACKING.md), the
[canonical backlog](../../SUBTASK_BACKLOG.md), [selected frontend additions](../../FEATURE_DIRECTION.md),
[source authority](../../SOURCES.md) and [delivery commitments](../../DELIVERY_PLAN.md).
It does not replace their contracts, duplicate the backlog or mark their cards done.

Keep normal page scrolling, clear bottom navigation, the chosen map-first Home,
Geoapify/flutter_map and explicit rider-started navigation. Preserve native Azure
account/Settings access. Website business rules apply; portal CSS, its Leaflet
implementation and its desktop breakpoint do not govern Flutter presentation.

HDB-01/02 and the separately selected
[PH map-focus extension](../philippines-map-focus/README.md) are merged.
HDB-03 is merged in PR 20. HDB-04 implementation and local evidence are also in
the merged mobile main used for HDB-05;
HDB-05 has selected headless local checks passing; native windows and live writes
remain pending as recorded in its evidence. Later dashboard/operations branches
remain planned. Creating this plan does not
create 17 work records, 17 branches or authorization to implement them together.
Backend code, docs, branch and uncommitted work remain read only in this task.

## Status and capacity

- Review: 43 existing related Flutter tests passed; five isolated diagnostic
  probes reproduced the five documented baseline defects. A green reproduction
  asserts observed bad behavior, not a successful repair.
- HDB-01 is merged and locally verified:
  161 tests passed with one expected configuration skip, clean analysis and
  ordinary Linux/Android builds. See its evidence for the added UI correction.
  HDB-02 is also locally verified: 179 tests with one expected skip, clean analysis
  and native builds; it is merged in PR 18, with physical acceptance separate.
  Other
  future HDB branches remain **planned**. Some reuse substantial implemented
  foundations; none is declared live accepted from those foundations alone.
- The complete selected sequence estimates **80–137 client hours**, including
  branch checks, excluding backend changes, merge waiting and external access
  delays. It overlaps the existing 315-hour backlog forecast and is not added to it.
- Re-estimate the chosen branch at activation. Use a 1–14 inclusive-day window,
  ending by November 20, 2026. November 21 remains the presentation assumption.
  Capacity is not established, so this is an order of work, not a guaranteed dated
  completion schedule. Agree an explicit scope/capacity decision if it will not fit.

The original review describes baseline BUG-H01–H05. HDB-01 owns the first two
repairs. HDB-02 owns BUG-H04/BUG-H05. BUG-H03, production write acceptance and
physical navigation remain with their selected later branches.
