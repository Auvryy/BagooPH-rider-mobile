# Rider detailed subtask backlog

Reviewed 2026-10-05. This catalog breaks the **16 major areas into 180 subtasks**
and **63 suggested batches**. It is a development plan; creating these docs does
not implement features or create individual future work records.

Current catalog status: **180 planned, 0 in progress,
0 blocked, 0 complete**. Check the [major task map](TASK_TRACKING.md)
and the current code for implementation evidence. IDs such as M02.03 and
B02-B are stable repository references, not external record IDs.

## How to select work

1. Request one subtask ID or a named batch below. A batch groups one to four
   related subtasks; it is a suggestion, not an instruction to open every branch.
2. Read the selected cards, their direct prerequisites and the prerequisites
   of those prerequisites. Numeric ID order is not dependency order: directions
   is needed before pickup, and the early M16 planning tasks run before release.
3. Re-read the current Bagoo website rules, roadmap, relevant code/tests and
   accepted API/deployment evidence across the affected roles. Follow
   [SOURCES.md](SOURCES.md), [AGENTS.md](../AGENTS.md) and the local work guide.
4. Implement only the requested scope. Report missing prerequisites; do not
   silently add their implementation to the request. A layout card may use
   explicitly labelled development fixtures where its scope allows them.
   Fixture evidence never clears an operational API or hardware prerequisite.
5. Before activation, choose a realistic 1–14 inclusive calendar-day window
   ending no later than November 20, with honest effort and satisfied dependencies.
   Create or reuse only the requested execution record; keep actual time measured.
6. Verify the card's checks and relevant cross-feature rules, save meaningful
   local commits, and report remaining limits. The user handles every push.
   Update catalog status and evidence only for work actually verified.

### Example later prompts

> Work on M01.01 only. Read its backlog card and current website sources,
> record the reviewed revision and dependencies, verify its checks, and commit locally.

> Implement B02-B: M02.03, M02.04 and M02.05. Check prerequisites and current
> website changes first. Keep unavailable operational features gated, verify
> the selected scope, and make meaningful local commits. I will push.

These are prompt examples for later work. They do not begin implementation now.

## Effort and calendar limits

The detailed client estimate is **315 h**, with a **213 h–499.5 h planning range**.
It covers the same baseline plus explicit integration, failure, privacy, device
and acceptance work; it excludes backend implementation and this
documentation effort. The earlier 130–204-hour coarse estimate is superseded
for future client planning, not an additional budget. See
[DELIVERY_PLAN.md](DELIVERY_PLAN.md) for the target and required scope decisions.

Client effort only, excluding backend implementation and documentation work recorded separately. Point estimates and rounded planning ranges are not measured time or probability bounds. Re-estimate selected work from current evidence.

Ranges are rounded per card to half-hour planning units around provisional
point estimates. They are not logged time, statistical confidence intervals
or a promise that all backend decisions will resolve inside them.

Windows reference the original delivery milestones only. They are tentative and do not reserve execution dates or establish capacity. Before activation, replan each selected task within 1–14 inclusive calendar days, with dependencies satisfied and a due date no later than 2026-11-20. If the complete baseline cannot fit, obtain an explicit scope decision without weakening safeguards.

The full point estimate requires about 48 client hours per week across
October 6–November 20, before backend effort. Several original milestone
windows are overloaded for one maintainer; the table below exposes that
problem rather than promising that all cards fit. Replan sequence/capacity
or agree a narrower honest demonstration. Preserve custody, authorization,
evidence, idempotency and money safeguards in any selected operational slice.

| Original reference | Tentative window, 2026 | Days | Detailed client effort | Hours per calendar day |
|---|---|---:|---:|---:|
| R01 | 2026-10-06 → 2026-10-08 | 3 | 23 h | 7.7 |
| R02 | 2026-10-09 → 2026-10-11 | 3 | 21 h | 7.0 |
| R03 | 2026-10-12 → 2026-10-17 | 6 | 25 h | 4.2 |
| R04 | 2026-10-18 → 2026-10-23 | 6 | 44.5 h | 7.4 |
| R05 | 2026-10-24 → 2026-10-29 | 6 | 21.5 h | 3.6 |
| R06 | 2026-10-30 → 2026-11-05 | 7 | 28 h | 4.0 |
| R07 | 2026-11-06 → 2026-11-10 | 5 | 23 h | 4.6 |
| R08 | 2026-11-11 → 2026-11-14 | 4 | 65 h | 16.2 |
| R09 | 2026-11-15 → 2026-11-17 | 3 | 34.5 h | 11.5 |
| R10 | 2026-11-18 → 2026-11-19 | 2 | 26.5 h | 13.2 |
| R11 | 2026-11-20 → 2026-11-20 | 1 | 3 h | 3.0 |

M16.01 belongs to early R01 planning and M16.02 to R03 interruption policy;
their inclusion here avoids postponing all reliability work until the end.
R11 contains rehearsal only. Shared windows require prerequisite ordering
inside them; they do not authorize concurrent unfinished dependencies.

## Major-area index

Every card has an outcome, implementation steps, explicit completion checks,
direct dependencies, external prerequisites, effort, a tentative milestone
window and a suggested batch. All completion checkboxes start unchecked.

| Area | Detailed cards | Subtasks | Batches | Point effort | Planning range |
|---|---|---:|---:|---:|---|
| M01 | [Shared API contract and website synchronization](backlog/M01.md) | 12 | 5 | 21.5 h | 15.5 h–33 h |
| M02 | [Flutter foundation and design system](backlog/M02.md) | 13 | 5 | 21 h | 14.5 h–33.5 h |
| M03 | [Authentication and account holding](backlog/M03.md) | 13 | 4 | 23.5 h | 16.5 h–37 h |
| M04 | [Home and task queues](backlog/M04.md) | 12 | 4 | 22.5 h | 16 h–35 h |
| M05 | [Duty and operational eligibility](backlog/M05.md) | 8 | 3 | 11.5 h | 7.5 h–18.5 h |
| M06 | [Pickup and origin-hub handoff](backlog/M06.md) | 12 | 3 | 21.5 h | 14.5 h–34.5 h |
| M07 | [Final-mile delivery and proof](backlog/M07.md) | 15 | 5 | 28 h | 19 h–44.5 h |
| M08 | [Failed delivery, returns and restricted recovery](backlog/M08.md) | 13 | 4 | 23 h | 15.5 h–37 h |
| M09 | [Directions and permitted contact](backlog/M09.md) | 8 | 3 | 10.5 h | 6.5 h–16.5 h |
| M10 | [Messages and chat](backlog/M10.md) | 12 | 4 | 21.5 h | 15 h–34 h |
| M11 | [Trips and recorded history](backlog/M11.md) | 10 | 3 | 16.5 h | 11 h–26.5 h |
| M12 | [Notifications](backlog/M12.md) | 9 | 3 | 15 h | 10 h–24.5 h |
| M13 | [Rider profile and assignment information](backlog/M13.md) | 9 | 3 | 14.5 h | 9.5 h–23.5 h |
| M14 | [Settings, security and help](backlog/M14.md) | 9 | 4 | 12.5 h | 7.5 h–19.5 h |
| M15 | [COD remittance and earnings visibility](backlog/M15.md) | 11 | 3 | 19.5 h | 13.5 h–31 h |
| M16 | [Reliability, Android acceptance and release](backlog/M16.md) | 14 | 7 | 32.5 h | 21 h–51 h |

## Requirement coverage

Use this map alongside the major-area screen map and the acceptance matrix.
The references identify planned implementation or checks; they are not
evidence that a requirement currently passes. Each selected slice also
inherits the shared authority, privacy and honest-state rules.

| Requirement | Planned implementation or acceptance cards |
|---|---|
| Current website rules and cross-role source review | [M01.01](backlog/M01.md#m01-01), [M01.12](backlog/M01.md#m01-12), [M16.01](backlog/M16.md#m16-01) |
| Accepted native auth, account and task contracts | [M01.03](backlog/M01.md#m01-03), [M01.04](backlog/M01.md#m01-04), [M03.01](backlog/M03.md#m03-01) |
| Separate approval, activity, placement and duty | [M03.08](backlog/M03.md#m03-08), [M03.09](backlog/M03.md#m03-09), [M05.01](backlog/M05.md#m05-01) |
| Pending, rejected, unplaced and restricted holding | [M03.08](backlog/M03.md#m03-08), [M03.09](backlog/M03.md#m03-09), [M03.13](backlog/M03.md#m03-13) |
| Positive role, ownership and foreign-resource denial | [M03.07](backlog/M03.md#m03-07), [M16.04](backlog/M16.md#m16-04) |
| Theme, four destinations, safe areas and controls | [M02.03](backlog/M02.md#m02-03), [M02.04](backlog/M02.md#m02-04), [M02.05](backlog/M02.md#m02-05), [M02.13](backlog/M02.md#m02-13) |
| Honest loading, empty, error, stale and unknown states | [M02.06](backlog/M02.md#m02-06), [M04.09](backlog/M04.md#m04-09) |
| Secure tokens, approved origin and private cleanup | [M02.08](backlog/M02.md#m02-08), [M03.05](backlog/M03.md#m03-05), [M03.10](backlog/M03.md#m03-10), [M16.04](backlog/M16.md#m16-04) |
| Logout, expiry and accepted session revocation | [M03.12](backlog/M03.md#m03-12), [M14.05](backlog/M14.md#m14-05), [M14.06](backlog/M14.md#m14-06) |
| Off-duty new-work exclusion and existing responsibility | [M05.03](backlog/M05.md#m05-03), [M05.05](backlog/M05.md#m05-05), [M05.07](backlog/M05.md#m05-07) |
| Scoped queues, pagination, selection, capacity and refresh | [M04.02](backlog/M04.md#m04-02), [M04.06](backlog/M04.md#m04-06), [M04.08](backlog/M04.md#m04-08), [M04.10](backlog/M04.md#m04-10) |
| Atomic pickup claim, stale eligibility and one winner | [M06.03](backlog/M06.md#m06-03), [M06.04](backlog/M06.md#m06-04), [M06.12](backlog/M06.md#m06-12) |
| Genuine matching scan, cancellation and phase ownership | [M06.06](backlog/M06.md#m06-06), [M06.07](backlog/M06.md#m06-07), [M07.03](backlog/M07.md#m07-03) |
| Seller collection, phase notes and pre-custody release | [M06.08](backlog/M06.md#m06-08), [M06.10](backlog/M06.md#m06-10), [M06.11](backlog/M06.md#m06-11) |
| Origin, mandatory Mother and destination hub custody | [M06.09](backlog/M06.md#m06-09), [M07.02](backlog/M07.md#m07-02), [M16.08](backlog/M16.md#m16-08) |
| Assigned departure and immutable delivered evidence | [M07.04](backlog/M07.md#m07-04), [M07.11](backlog/M07.md#m07-11), [M07.13](backlog/M07.md#m07-13), [M07.15](backlog/M07.md#m07-15) |
| Genuine private proof, picker recovery and scoped retrieval | [M07.07](backlog/M07.md#m07-07), [M07.08](backlog/M07.md#m07-08), [M07.09](backlog/M07.md#m07-09), [M11.05](backlog/M11.md#m11-05) |
| Recipient evidence, exact COD and explicit no-COD | [M07.05](backlog/M07.md#m07-05), [M07.06](backlog/M07.md#m07-06), [M07.10](backlog/M07.md#m07-10) |
| Uncertain responses, same-intent replay and rollback | [M01.06](backlog/M01.md#m01-06), [M07.12](backlog/M07.md#m07-12), [M16.03](backlog/M16.md#m16-03) |
| Buyer-only receipt and narrow existing-order access | [M07.13](backlog/M07.md#m07-13), [M07.15](backlog/M07.md#m07-15), [M16.08](backlog/M16.md#m16-08) |
| Allowed failure reasons and recorded attempts | [M08.01](backlog/M08.md#m08-01), [M08.03](backlog/M08.md#m08-03), [M08.04](backlog/M08.md#m08-04), [M08.12](backlog/M08.md#m08-12) |
| Hub return before approved retry, refusal and third-failure RTS | [M08.05](backlog/M08.md#m08-05), [M08.06](backlog/M08.md#m08-06), [M08.07](backlog/M08.md#m08-07), [M08.08](backlog/M08.md#m08-08) |
| Restricted parcel/cash recovery before reassignment | [M08.09](backlog/M08.md#m08-09), [M08.10](backlog/M08.md#m08-10), [M08.11](backlog/M08.md#m08-11), [M08.13](backlog/M08.md#m08-13) |
| Reverse Mother-Hub route and seller-only return receipt | [M08.08](backlog/M08.md#m08-08), [M08.12](backlog/M08.md#m08-12), [M16.09](backlog/M16.md#m16-09) |
| Authorized stop/contact, coordinates and directions fallback | [M09.01](backlog/M09.md#m09-01), [M09.02](backlog/M09.md#m09-02), [M09.03](backlog/M09.md#m09-03), [M09.04](backlog/M09.md#m09-04), [M09.05](backlog/M09.md#m09-05) |
| Phase-bound chat, safe drafts, displayed reads and replay | [M10.06](backlog/M10.md#m10-06), [M10.07](backlog/M10.md#m10-07), [M10.08](backlog/M10.md#m10-08), [M10.10](backlog/M10.md#m10-10), [M10.11](backlog/M10.md#m10-11) |
| Recorded scoped final-mile history and private proof | [M11.01](backlog/M11.md#m11-01), [M11.02](backlog/M11.md#m11-02), [M11.04](backlog/M11.md#m11-04), [M11.10](backlog/M11.md#m11-10) |
| Durable notifications, own read, deduplication and safe links | [M12.01](backlog/M12.md#m12-01), [M12.04](backlog/M12.md#m12-04), [M12.05](backlog/M12.md#m12-05), [M12.07](backlog/M12.md#m12-07), [M12.08](backlog/M12.md#m12-08) |
| Managed identity/vehicle/placement and permitted profile edits | [M13.03](backlog/M13.md#m13-03), [M13.04](backlog/M13.md#m13-04), [M13.05](backlog/M13.md#m13-05), [M13.07](backlog/M13.md#m13-07) |
| Password, help, identity review and account-closure boundaries | [M14.04](backlog/M14.md#m14-04), [M14.05](backlog/M14.md#m14-05), [M14.07](backlog/M14.md#m14-07), [M14.08](backlog/M14.md#m14-08) |
| Distinct held/remitted cash and append-only discrepancies | [M15.03](backlog/M15.md#m15-03), [M15.06](backlog/M15.md#m15-06), [M15.07](backlog/M15.md#m15-07) |
| Reconciliation, seller-settlement gates and confirmed earnings | [M15.08](backlog/M15.md#m15-08), [M15.09](backlog/M15.md#m15-09), [M15.11](backlog/M15.md#m15-11) |
| Physical Android camera, permissions and process lifecycle | [M16.05](backlog/M16.md#m16-05), [M16.06](backlog/M16.md#m16-06) |
| Large text, screen readers, focus, contrast and touch targets | [M02.13](backlog/M02.md#m02-13), [M16.07](backlog/M16.md#m16-07) |
| Deployed API privacy, proxy/cache and client compatibility | [M01.11](backlog/M01.md#m01-11), [M16.10](backlog/M16.md#m16-10) |
| Approved app identity, private signing and reproducible build | [M16.11](backlog/M16.md#m16-11), [M16.12](backlog/M16.md#m16-12), [M16.13](backlog/M16.md#m16-13) |
| Genuine isolated role actions, known limits and rehearsal | [M16.08](backlog/M16.md#m16-08), [M16.09](backlog/M16.md#m16-09), [M16.14](backlog/M16.md#m16-14) |
| Onboarding, maps, offline drafts, push, wallet and platform decisions | [M01.02](backlog/M01.md#m01-02), [M03.11](backlog/M03.md#m03-11), [M09.07](backlog/M09.md#m09-07), [M12.08](backlog/M12.md#m12-08), [M15.09](backlog/M15.md#m15-09), [M16.02](backlog/M16.md#m16-02), [M16.11](backlog/M16.md#m16-11) |

## External prerequisite register

These entries define required evidence, not a declaration that the backend
is ready. Check the relevant current implementation/contract/device record
for each selected card; accepted paper payloads do not satisfy live gates.
Backend implementation stays with its owner and its current roadmap.

<a id="gate-auth"></a>

### AUTH

Accepted native token/me contract, positive courier eligibility, holding access, expiry and revocation tests.

Catalog state: requires current evidence. Record the accepted source/API
revision and relevant passing checks before operational integration.

<a id="gate-tasks"></a>

### TASKS

Accepted scoped queues/detail/capacity resources, stable assignment IDs and current permitted actions.

Catalog state: requires current evidence. Record the accepted source/API
revision and relevant passing checks before operational integration.

<a id="gate-duty"></a>

### DUTY

Accepted explicit availability mutation preserving approval, placement and existing custody.

Catalog state: requires current evidence. Record the accepted source/API
revision and relevant passing checks before operational integration.

<a id="gate-pickup"></a>

### PICKUP

Accepted atomic claims, matching submitted waybill, handoff evidence and pre-custody release policy after applicable Phase 0 gates.

Catalog state: requires current evidence. Record the accepted source/API
revision and relevant passing checks before operational integration.

<a id="gate-hubs"></a>

### HUBS

Accepted ordered origin/Mother/destination hub custody and required manifest gates; hub actions remain web-owned.

Catalog state: requires current evidence. Record the accepted source/API
revision and relevant passing checks before operational integration.

<a id="gate-outcomes"></a>

### OUTCOMES

Accepted assigned departure, immutable private proof, recipient/exact COD evidence and idempotent outcome/reconciliation API.

Catalog state: requires current evidence. Record the accepted source/API
revision and relevant passing checks before operational integration.

<a id="gate-exceptions"></a>

### EXCEPTIONS

Backend Phase 3 attempt records, hub-return custody, approved retry/refusal/third-failure RTS and seller receipt accepted.

Catalog state: requires current evidence. Record the accepted source/API
revision and relevant passing checks before operational integration.

<a id="gate-recovery"></a>

### RECOVERY

Accepted reasoned restriction and narrow parcel/cash recovery capability without reopening ordinary access.

Catalog state: requires current evidence. Record the accepted source/API
revision and relevant passing checks before operational integration.

<a id="gate-messages"></a>

### MESSAGES

Accepted current parcel-phase recipient, plain-text send/replay and selected displayed-message read boundary.

Catalog state: requires current evidence. Record the accepted source/API
revision and relevant passing checks before operational integration.

<a id="gate-trips"></a>

### TRIPS

Accepted scoped paginated history/checkpoints and purpose-authorized private evidence resource.

Catalog state: requires current evidence. Record the accepted source/API
revision and relevant passing checks before operational integration.

<a id="gate-notifications"></a>

### NOTIFICATIONS

Backend Phase 4 durable deduplicated events, own read state and authorized resource links accepted.

Catalog state: requires current evidence. Record the accepted source/API
revision and relevant passing checks before operational integration.

<a id="gate-profile"></a>

### PROFILE

Accepted own-profile allowlist and canonical validators, with managed placement and reviewed identity boundaries.

Catalog state: requires current evidence. Record the accepted source/API
revision and relevant passing checks before operational integration.

<a id="gate-password"></a>

### PASSWORD

Accepted current-password/email-verification rules, safe validation and native session revocation decision.

Catalog state: requires current evidence. Record the accepted source/API
revision and relevant passing checks before operational integration.

<a id="gate-finance"></a>

### FINANCE

Backend Phase 5 append-only collection/remittance/discrepancy/reconciliation and confirmed earnings accepted.

Catalog state: requires current evidence. Record the accepted source/API
revision and relevant passing checks before operational integration.

<a id="gate-staging"></a>

### STAGING

Approved deployed revision, HTTPS JSON, proxy/cache/upload safeguards and isolated synthetic cross-role accounts.

Catalog state: requires current evidence. Record the accepted source/API
revision and relevant passing checks before operational integration.

<a id="gate-android"></a>

### ANDROID

Compatible SDK/JDK, physical Android device and required platform permission/lifecycle verification available.

Catalog state: requires current evidence. Record the accepted source/API
revision and relevant passing checks before operational integration.

## Keeping the backlog current

The canonical editable source is [planning/subtasks.json](planning/subtasks.json).
The index and sixteen area pages are generated views. Keep existing IDs stable;
add new bounded cards instead of renumbering old references. Split or replan
a selected batch if current scope, API changes or capacity make it too large.

```sh
python tool/render_rider_backlog.py
python tool/render_rider_backlog.py --check
```

Validation checks unique/sequential IDs, area coverage, batch ownership,
resolved requirement references, acyclic task and batch dependencies,
evidence for completed cards,
effort ranges, timezone, calendar limits and generated-page consistency.
It does not prove live API, deployed website or physical-device readiness.

Feature checks are incremental acceptance for each implemented slice.
M16 checks whole-app integration, device/process behavior and release evidence;
they do not replace those incremental checks or double-count their execution.

When a selected slice finishes, attach real evidence to its catalog status,
update the major map's remaining work and affected flow/API/readiness docs,
and keep backend acceptance evidence in the owning project. Major areas stay
unfinished until their required cards and area-level acceptance are verified.
