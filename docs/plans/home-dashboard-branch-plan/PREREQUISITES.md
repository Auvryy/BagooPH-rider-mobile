# Prerequisite audit and selected-scope boundaries

Derived October 13 from the canonical `docs/planning/subtasks.json` (180 cards),
not from guesses about card numbering. This document is a dependency read, not
new backlog data or status changes.

## How to use the two dependency systems

HDB predecessors are implementation deliveries and required selected acceptance.
Backlog references in a brief identify partial implementation and later coverage
within broader cards. They do not select every whole card as a prerequisite or
assert its completion. The table below discloses the full canonical dependencies
of those associated cards so later prompts cannot quietly overlook them.

At activation, inspect each dependency against the actual selected behavior and
current source/acceptance. Reuse implemented account/theme/transport foundations
when evidence supports them. Missing required ingredients get a precise owning
handoff; they are not implemented silently in the current branch.

Card-wide later verification remains open until its full required scope exists.
For example, HDB-06 prepares original-byte/typed-intent safety, but does not finish
M16.03's later cross-feature acceptance before delivery/messages/cash exist.
HDB-01/02 verify the affected current cleanup paths, not every future proof draft.
This distinction avoids creating an artificial cycle between a foundation branch
and the later behavior that will ultimately verify the broader card.

## Full canonical closure of associated coverage

Ranges below contain only existing contiguous IDs. Counts include the associated
cards themselves. Gate codes are the union from those cards and their dependency
closure, with their original meanings retained.

| Branch | Associated/full-closure card counts | Full canonical ID closure | Canonical external gates |
|---|---|---|---|
| HDB-01 | 7 / 120 | M01.01–M01.11, M02.01–M02.12, M03.01–M03.13, M04.01–M04.12, M05.01–M05.03, M05.05–M05.07, M07.01, M07.05–M07.14, M08.01–M08.03, M08.05–M08.06, M08.09–M08.11, M08.13, M09.01–M09.04, M10.01–M10.09, M10.11, M11.01, M13.01–M13.09, M14.01–M14.09, M15.01–M15.10, M16.01–M16.02, M16.04 | ANDROID, AUTH, DUTY, EXCEPTIONS, FINANCE, HUBS, MESSAGES, OUTCOMES, PASSWORD, PROFILE, RECOVERY, STAGING, TASKS, TRIPS |
| HDB-02 | 5 / 126 | M01.01–M01.11, M02.01–M02.12, M03.01–M03.13, M04.01–M04.11, M05.01–M05.03, M05.05–M05.07, M07.01, M07.05–M07.14, M08.01–M08.03, M08.05–M08.06, M08.09–M08.11, M08.13, M09.01–M09.08, M10.01–M10.12, M11.01, M13.01–M13.09, M14.01–M14.09, M15.01–M15.10, M16.01–M16.02, M16.04, M16.06 | ANDROID, AUTH, DUTY, EXCEPTIONS, FINANCE, HUBS, MESSAGES, OUTCOMES, PASSWORD, PROFILE, RECOVERY, STAGING, TASKS, TRIPS |
| HDB-03 | 7 / 38 | M01.01–M01.06, M01.11, M02.01–M02.11, M03.01–M03.07, M04.01–M04.09, M05.01–M05.02, M05.06, M16.02 | ANDROID, AUTH, DUTY, TASKS |
| HDB-04 | 8 / 52 | M01.01–M01.08, M01.11, M02.01–M02.11, M03.01–M03.07, M03.10, M04.01–M04.09, M04.11, M05.01, M05.06, M06.01–M06.03, M06.05, M07.01–M07.02, M09.01–M09.05, M16.02 | ANDROID, AUTH, DUTY, HUBS, OUTCOMES, PICKUP, TASKS |
| HDB-05 | 14 / 166 | M01.01–M01.11, M02.01–M02.12, M03.01–M03.13, M04.01–M04.11, M05.01–M05.08, M06.01–M06.12, M07.01–M07.15, M08.01–M08.13, M09.01–M09.04, M10.01–M10.12, M11.01–M11.10, M12.01–M12.09, M13.01–M13.09, M14.01–M14.09, M15.01–M15.11, M16.01–M16.04, M16.08–M16.10 | ANDROID, AUTH, DUTY, EXCEPTIONS, FINANCE, HUBS, MESSAGES, NOTIFICATIONS, OUTCOMES, PASSWORD, PICKUP, PROFILE, RECOVERY, STAGING, TASKS, TRIPS |
| HDB-06 | 10 / 144 | M01.01–M01.11, M02.01–M02.12, M03.01–M03.13, M04.01–M04.11, M05.01–M05.08, M06.01–M06.12, M07.01–M07.15, M08.01–M08.13, M09.01–M09.04, M10.01–M10.12, M11.01, M13.01–M13.09, M14.01–M14.09, M15.01–M15.10, M16.01–M16.04 | ANDROID, AUTH, DUTY, EXCEPTIONS, FINANCE, HUBS, MESSAGES, OUTCOMES, PASSWORD, PICKUP, PROFILE, RECOVERY, STAGING, TASKS, TRIPS |
| HDB-07 | 8 / 84 | M01.01–M01.08, M01.11, M02.01–M02.12, M03.01–M03.13, M04.01–M04.11, M05.01–M05.04, M05.06, M06.01–M06.12, M07.01–M07.15, M09.01–M09.04, M16.01–M16.02, M16.05 | ANDROID, AUTH, DUTY, HUBS, OUTCOMES, PICKUP, RECOVERY, STAGING, TASKS |
| HDB-08 | 6 / 84 | M01.01–M01.08, M01.11, M02.01–M02.12, M03.01–M03.13, M04.01–M04.11, M05.01–M05.04, M05.06, M06.01–M06.12, M07.01–M07.15, M09.01–M09.04, M16.01–M16.02, M16.05 | ANDROID, AUTH, DUTY, HUBS, OUTCOMES, PICKUP, RECOVERY, STAGING, TASKS |
| HDB-09 | 11 / 58 | M01.01–M01.07, M01.11, M02.01–M02.12, M03.01–M03.07, M03.10, M04.01–M04.07, M04.09, M04.11, M06.06, M07.01–M07.15, M09.01–M09.04, M16.02 | ANDROID, AUTH, HUBS, OUTCOMES, STAGING, TASKS |
| HDB-10 | 9 / 61 | M01.01–M01.08, M01.11, M02.01–M02.12, M03.01–M03.07, M03.10, M04.01–M04.07, M04.09–M04.10, M07.01, M07.05–M07.12, M08.01–M08.08, M08.12, M09.01–M09.04, M16.02 | ANDROID, AUTH, EXCEPTIONS, HUBS, OUTCOMES, STAGING, TASKS |
| HDB-11 | 10 / 60 | M01.01–M01.07, M01.09, M01.11, M02.01–M02.12, M03.01–M03.07, M03.10, M04.01–M04.07, M04.09, M04.11, M07.01, M07.05–M07.14, M11.01–M11.10, M16.02 | ANDROID, AUTH, OUTCOMES, STAGING, TASKS, TRIPS |
| HDB-12 | 9 / 49 | M01.01–M01.11, M02.01–M02.11, M03.01–M03.07, M03.10, M04.01–M04.07, M04.09–M04.10, M12.01–M12.09, M16.02 | ANDROID, AUTH, NOTIFICATIONS, STAGING, TASKS |
| HDB-13 | 12 / 49 | M01.01–M01.06, M01.09, M01.11, M02.01–M02.11, M03.01–M03.07, M03.10, M04.01–M04.07, M04.09–M04.10, M10.01–M10.12, M16.02 | ANDROID, AUTH, MESSAGES, STAGING, TASKS |
| HDB-14 | 10 / 70 | M01.01–M01.07, M01.09–M01.11, M02.01–M02.12, M03.01–M03.07, M03.10, M04.01–M04.07, M04.09, M04.11, M07.01, M07.05–M07.14, M09.01–M09.04, M11.01, M13.01–M13.02, M14.01, M15.01–M15.11, M16.02 | ANDROID, AUTH, FINANCE, HUBS, OUTCOMES, PROFILE, STAGING, TASKS, TRIPS |
| HDB-15 | 6 / 70 | M01.01–M01.07, M01.09–M01.11, M02.01–M02.12, M03.01–M03.07, M03.10, M04.01–M04.07, M04.09, M04.11, M07.01, M07.05–M07.14, M09.01–M09.04, M11.01, M13.01–M13.02, M14.01, M15.01–M15.11, M16.02 | ANDROID, AUTH, FINANCE, HUBS, OUTCOMES, PROFILE, STAGING, TASKS, TRIPS |
| HDB-16 | 5 / 125 | M01.01–M01.11, M02.01–M02.12, M03.01–M03.13, M04.01–M04.11, M05.01–M05.03, M05.05–M05.07, M06.01–M06.03, M06.05–M06.07, M07.01, M07.05–M07.14, M08.01–M08.03, M08.05–M08.06, M08.09–M08.11, M08.13, M09.01–M09.04, M10.01–M10.09, M10.11, M11.01, M13.01–M13.09, M14.01–M14.09, M15.01–M15.10, M16.01–M16.02, M16.04 | ANDROID, AUTH, DUTY, EXCEPTIONS, FINANCE, HUBS, MESSAGES, OUTCOMES, PASSWORD, PICKUP, PROFILE, RECOVERY, STAGING, TASKS, TRIPS |
| HDB-17 | 9 / 177 | M01.01–M01.11, M02.01–M02.12, M03.01–M03.13, M04.01–M04.12, M05.01–M05.08, M06.01–M06.12, M07.01–M07.15, M08.01–M08.13, M09.01–M09.08, M10.01–M10.12, M11.01–M11.10, M12.01–M12.09, M13.01–M13.09, M14.01–M14.09, M15.01–M15.11, M16.01–M16.13 | ANDROID, AUTH, DUTY, EXCEPTIONS, FINANCE, HUBS, MESSAGES, NOTIFICATIONS, OUTCOMES, PASSWORD, PICKUP, PROFILE, RECOVERY, STAGING, TASKS, TRIPS |

## Gate meanings from the owner backlog

| Code | Canonical requirement |
|---|---|
| AUTH | Accepted native token/me contract, positive courier eligibility, holding access, expiry and revocation tests. |
| TASKS | Accepted scoped queues/detail/capacity resources, stable assignment IDs and current permitted actions. |
| DUTY | Accepted explicit availability mutation preserving approval, placement and existing custody. |
| PICKUP | Accepted atomic claims, matching submitted waybill, handoff evidence and pre-custody release policy after applicable Phase 0 gates. |
| HUBS | Accepted ordered origin/Mother/destination hub custody and required manifest gates; hub actions remain web-owned. |
| OUTCOMES | Accepted assigned departure, immutable private proof, recipient/exact COD evidence and idempotent outcome/reconciliation API. |
| EXCEPTIONS | Backend Phase 3 attempt records, hub-return custody, approved retry/refusal/third-failure RTS and seller receipt accepted. |
| RECOVERY | Accepted reasoned restriction and narrow parcel/cash recovery capability without reopening ordinary access. |
| MESSAGES | Accepted current parcel-phase recipient, plain-text send/replay and selected displayed-message read boundary. |
| TRIPS | Accepted scoped paginated history/checkpoints and purpose-authorized private evidence resource. |
| NOTIFICATIONS | Backend Phase 4 durable deduplicated events, own read state and authorized resource links accepted. |
| PROFILE | Accepted own-profile allowlist and canonical validators, with managed placement and reviewed identity boundaries. |
| PASSWORD | Accepted current-password/email-verification rules, safe validation and native session revocation decision. |
| FINANCE | Backend Phase 5 append-only collection/remittance/discrepancy/reconciliation and confirmed earnings accepted. |
| STAGING | Approved deployed revision, HTTPS JSON, proxy/cache/upload safeguards and isolated synthetic cross-role accounts. |
| ANDROID | Compatible SDK/JDK, physical Android device and required platform permission/lifecycle verification available. |

## Supported native subset versus broader deferred cards

- Native v1 explicitly disables release, restricted recovery and earnings.
  The full PICKUP/RECOVERY/FINANCE card families include broader policies; the
  selected HDB branches consume only supported ordinary claim/scan/outcome,
  retained read and offer behavior. Unsupported M06.10, M08.10–M08.11 and M15.09
  implementation is not activated or claimed complete.
- HDB-10 covers ordinary failure/return and owner-approved retry/RTS guidance.
  HDB-17 must identify whether owner-controlled website recovery is exercised;
  it does not fabricate a native recovery route or complete untested restricted
  subcases of wider M08/M16 cards.
- Pending capability/schema/deployment, genuine original proof, role authority,
  exact cash and real Android requirements are not waived by that scope split.
  API-H01–H08 and the selected branch checks are the concrete acceptance boundary.
- The map/location extension is the separately selected native scope under M09.07,
  even though the website plan itself does not supply live rider GPS. Keep its
  existing rider-started Android service rules; do not expand it into fleet tracking.
- Full-card planning windows/statuses in the canonical backlog remain unchanged.
  They are tentative earlier forecasts. Re-estimate and schedule only the selected
  execution branch within the delivery policy, rather than treating every inherited
  window as a current commitment.

See [BRANCHES.md](BRANCHES.md), [ACCEPTANCE.md](ACCEPTANCE.md),
[the API checklist](../../api/HOME_DASHBOARD_NEEDS.md) and the
[canonical backlog](../../SUBTASK_BACKLOG.md). A prerequisite check is evidence,
not permission to start an unrequested role/API release.
