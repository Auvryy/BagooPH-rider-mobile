# Proposed Home/dashboard blueprint

This is a proposal for the selected HDB branches. The [review](REVIEW.md) describes
current runtime behavior; a box in this document is not an implemented feature.
Preserve the existing native theme and the user's normal-scroll/no-drag preference.

## Phone reading order

```text
Workspace header: branding + Profile
Navigation status: active/starting controls, or paused reason + revalidation action
Home scope: rider greeting + company/hub + one duty control
Checked time / stale notice / useful eligibility or pending-request message
Bounded map with current real pins/route, Recenter and visible attribution
Three counted choices: Available pickups | My pickups | Assigned delivery
Selected responsibility: full identifier, stage, stop, next actor/action, COD
Normal scrollable task rows + optional loaded-row search + Load more
Connected additions when accepted: recorded work / notices / cash responsibility
Bottom navigation outside content: Tasks | Trips | Messages | Profile
```

Keep one page scroll. Do not restore a draggable sheet, floating footer over
content or multiple competing task scroll areas on phones. At 200% text, all
required controls can reflow into readable rows. Large windows keep map/tasks
beside one another; platform preview framing stays optional.

The website recommends task essentials before its map. The selected native Home
remains map-first; improve its bounded height and work-control reach instead of
silently replacing the agreed native direction with portal layout/CSS.

## Content and data ownership

| Proposed content | Current source / rule | Branch |
|---|---|---|
| Company/hub and one duty control | Home placement, on_duty, eligibility and actual command state; distinguish missing name from missing assignment | HDB-03/HDB-05 |
| Available/My pickups/Assigned delivery counts | Exact returned Home counts; unknown/stale is labelled, never invented zero | HDB-03 |
| Pickup capacity | Returned active/limit/remaining values; no fixed client capacity | HDB-03 |
| Last checked and refresh | Home/task observed_at and actual refresh outcome; no fictional always-live feed | HDB-01/HDB-03 |
| Selected current responsibility | Fresh owned detail or seller-only available preview; full identifiers, friendly stage, current custody/stop and next_instruction | HDB-03/HDB-04 |
| Useful recovery region | Recoverable read failure, retained stale data, denied access, cooldown and unresolved original UUID are distinct | HDB-01/HDB-06 |
| Focused Stop Mode | Work this stop; directions/copy/call/notes and one actually implemented permitted transition | HDB-04/HDB-07–10 |
| Doorstep Guide | Actual buyer stop.instructions first; no invented seller/hub landmark, unit, photo or next address | HDB-04; API-H06 only if extending source |
| Latest recorded work | A small, explicitly scoped set of real returned Trips, with a link to full retained history | HDB-11 |
| Notice inbox and badge | Server-owned notification unread_count and durable displayed reads | HDB-12 |
| Message current participant | Resolve the authorized assignment/phase thread and current can_send; no generic buyer/seller selector | HDB-13 |
| Cash responsibility | Cash list's all-owned-journals held summary and actual receipt/pending/discrepancy facts; earnings unavailable | HDB-14/HDB-15 |
| Parcel Finder slot | Personal owned-parcel label, proposed session-only first; never proof of scan, assignment or custody | HDB-16 |

## Selected stop and work actions

| Current responsibility | Primary behavior when connected | Boundary |
|---|---|---|
| Available pickup preview | Claim pickup after current eligibility/version acceptance | No buyer/payment/contact leak or Navigate before ownership |
| Owned pickup awaiting seller collection | Real scan/review, then confirm collection | Assignment is not physical possession |
| Collected pickup | Origin-hub address/directions and Awaiting hub intake | Hub handler records receipt |
| Hub-assigned final-mile task | Real scan/review, then depart | Hub assigns; rider cannot self-assign |
| Out for delivery, permitted COD | Recipient, genuine proof and exact cash handoff | Rider records delivered; buyer completes separately |
| Failed attempt | Required failure evidence, returned hub instruction | Rider retains custody until hub receipt; hub approves retry/RTS |
| Recorded terminal work | Show committed result and returned history identity | Do not keep an expired active task as an actionable card |

Backend actions are hints, rechecked by server commands. The mobile build must
also have a connected/accepted handler. A true server pickup/deliver flag alone
cannot make an unfinished Flutter action appear functional. Unavailable buttons
need a useful rider explanation, not raw API or build-configuration terminology.

## Map, selection and search

- Render only valid returned current-stop coordinates; no geocoded or guessed
  destination. Address text and explicit external directions remain useful.
- Keep attribution visible with the map and clear of task/navigation controls.
  Limit long error notices in the map's drawable area; place explanation/retry in
  ordinary page content if needed.
- Offer purposeful selected-stop/queue/route framing. Label a no-target overview
  honestly; decide view-driven tile loading for empty/unlocated/offstage Home.
- Keep route and navigation lifecycle outside Home. Panning disables following
  until Recenter; hiding/remounting the map must not silently reset that choice.
- Queue counts describe the server queue; current search covers loaded rows. Show
  loaded/total context where available. Add server search only through a selected
  contract extension.
- Keep a selected responsibility distinct from the filtered list. If it remains
  selected outside a filter, explain that state and retain only authorized detail;
  never silently navigate to a different parcel just because its row is first.
- Do not reorder server work as optimized/nearest/best. First-load preference for
  existing responsibilities is presentation, not a dispatch priority claim.

## What is deliberately deferred

Delivered-today totals and full activity charts need an authoritative native
aggregate with actor scope, date basis, timezone and completeness. A limited
Trip page filtered by assignment date cannot provide them. Global unread-chat
counts likewise need a complete aggregate or an explicit loaded-chat label.

No earnings guess, bank/payout flow, multi-stop optimizer, automatic arrival,
proximity outcome, spoken turn-by-turn engine, background tracking merely from
duty or location-history upload enters this blueprint. The user-selected Android
navigation continues only after Navigate, with its existing authorization boundary.

Structured seller/hub instructions, verified seller coordinates, native hub
coordinates and non-COD handoff are separate backend requests if selected. Existing
coordinate nulls, missing instructions and unsupported earnings remain honest.

## Acceptance bar

Use [the acceptance matrix](ACCEPTANCE.md) per branch. The dashboard should answer
what work is mine, where the current stop is, what I may do next, why something is
unavailable and which recorded data was checked. Decoration, a populated fixture
or a successful build cannot answer those questions on behalf of the server.
