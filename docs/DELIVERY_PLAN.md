# Delivery plan to the November presentation

Planning starts October 5, 2026. Working presentation date: **November 21, 2026**,
Asia/Manila. **November 20 is the latest development deadline**, reserved for
final verification, freeze and rehearsal. Confirm the institution's exact date
when available; this is the current planning assumption.

The web project's own completion target remains November 20. This client plan
does not reschedule its other developer, change its branch, or authorize bypassing
the backend's phase order. Calendar targets do not waive operational safeguards.

## Capacity and assumptions

- One mobile maintainer is assumed. Backend work is coordinated with the web
  maintainer; its effort is not included below or assumed to be free.
- The proposed client work totals **130–204 focused hours**, including docs and
  verification, roughly **20–31 hours per week** over this delivery window.
  These are planning ranges, not logged time or a measured productivity result.
- Backend adapters, incomplete core-flow work, Android setup, deployment review,
  device availability, and contract decisions can extend effort beyond this range.
- Every execution task uses **1–14 inclusive calendar days**, an effort estimate,
  explicit acceptance and a real dependency. Split a phase into smaller tasks
  when its scope cannot fit; a broad feature name is not a two-week loophole.
- This is a proposed plan. Only the currently requested docs work is being
  performed here; future rows are not automatically created tasks or approved
  coding branches. Re-estimate from evidence after the first integrated slice.

## Task names and ownership

Every execution task title starts with **`rider-mobile/`**, followed by a natural
description. For example: `rider-mobile/document pickup and delivery` or
`rider-mobile/add courier sign-in`. Apply this format when creating work from
the proposed rows below; their R00–R11 identifiers are planning references.

Before every task mutation, re-read the target and require that exact title
prefix. Only those records may receive edits, status/date changes, checklists,
comments, timers/time entries, dependencies or attachments, or be deleted.
Keep the prefix in title edits. Web tasks and shared parent/label/sprint records
remain unchanged; their names or Rider labels do not grant mobile edit scope.
Backend dependencies may be read/referenced without changing their records.

For an explicitly requested migration of an existing verified mobile task,
rename it once while preserving other fields, then verify the prefix before
further changes. Task text remains limited to BagooPH Rider work and actual
checks under the root `AGENTS.md` and local guide.

## Proposed sequence

| Item | Start | Due | Calendar days | Client effort | Prerequisite and finish evidence |
|---|---|---|---:|---:|---|
| R00 Rider plan and source adaptation | Oct 5 | Oct 6 | 2 | 3–4 h | Scope, flow, API proposal, local work guide and doc checks |
| R01 Agree first API slice | Oct 6 | Oct 8 | 3 | 6–10 h | Backend owner agrees auth/me/task schema, policies, errors and limits; R00 handoff |
| R02 App foundation and device baseline | Oct 9 | Oct 11 | 3 | 8–12 h | Agreed contract; feature structure, router/theme/transport adapters; Android toolchain and phone available |
| R03 Sign-in and holding | Oct 12 | Oct 17 | 6 | 14–22 h | Staging token/me endpoints and positive access tests; login, expiry/logout, pending/restricted states work on phone |
| R04 Queues, stop detail and duty | Oct 18 | Oct 23 | 6 | 12–18 h | Scoped task queries and placement/capacity policy; truthful errors/empty data and off-duty existing work |
| R05 Pickup claim and waybill | Oct 24 | Oct 29 | 6 | 16–24 h | Backend prerequisite phase accepted; matching scan, one claim winner, origin-hub intake visible cross-role |
| R06 Final-mile departure and proof | Oct 30 | Nov 5 | 7 | 18–28 h | Assigned departure/outcome API, immutable proof and exact COD record; duplicate/timeout/storage-failure checks |
| R07 Failed delivery and recovery | Nov 6 | Nov 10 | 5 | 14–22 h | Backend Phase 3 accepted; reasons, hub return, retry/third failure/RTS observed without rider overreach |
| R08 Messages, trips and permitted profile | Nov 11 | Nov 14 | 4 | 14–20 h | Scoped APIs and shared validation; stale-phase drafts, selected reads, pagination and contact/password boundaries |
| R09 Notifications and cash visibility | Nov 15 | Nov 17 | 3 | 10–18 h | Backend Phases 4/5 accepted; persistent read state and real held/remitted/reconciled amounts, no fake earnings |
| R10 Cross-role checks and fixes | Nov 18 | Nov 19 | 2 | 12–20 h | Real phone, isolated tests and staging deployment; acceptance matrix and unresolved issues reviewed |
| R11 Freeze and rehearsal | Nov 20 | Nov 20 | 1 | 3–6 h | Reproducible build/demo, reviewed evidence, backup and honest known limits; no new features |

All dates are in 2026. A shared date is a handoff, not a promise of simultaneous
full-time work. R01 may start on October 6 only after R00's relevant contract
draft is ready. The 130–204-hour total is the sum of these ranges. Developer
availability and backend progress must be reviewed, not inferred from this table.

## Gates and scope decisions

| Checkpoint | Decision |
|---|---|
| Oct 8 | Freeze first auth/me/task conventions. Decide native onboarding versus existing web onboarding, token expiry, API origin and device baseline |
| Oct 17 | If real-phone auth/access is not accepted, replan custody dates before adding more screens |
| Oct 23 | Confirm backend approval/placement/capacity and scan prerequisites; UI-only queues cannot count as operations |
| Nov 5 | Confirm normal mobile handoff and backend evidence gates; prioritize exceptions and financial correctness over optional maps/polish |
| Nov 10 | If exception custody is incomplete, report a constrained demo and get a scope decision; do not claim full rider readiness |
| Nov 17 | Stop adding capabilities. Resolve missing notification/cash acceptance or clearly record it as unfinished |
| Nov 19 | Complete device and cross-role evidence; critical unresolved safeguards block the affected operation/demo claim |
| Nov 20 | Freeze/rehearse the reviewed build and dataset; if an urgent fix is necessary, repeat the affected checks before freeze |

Read the backend's current roadmap before each gate. Its phases remain serial:
Phase 0 access/safety, Phase 1 normal commerce, Phase 2 physical manifests,
Phase 3 exceptions/self-pickup, Phase 4 persistent notifications, Phase 5 finance,
Phase 6 cross-role cleanup. Mobile layout work with fixtures may progress
independently; operational adapters must wait for applicable accepted prerequisites.

If capacity is insufficient, first remove optional native maps, animation,
native onboarding duplication and additional tooling. Do not remove approval,
scope, evidence, hub-return, idempotency, or cash safeguards to hit the date.
If the complete core transaction still cannot fit, report its remaining work and
agree what can be presented. A narrower honest demonstration is not completion
of the full baseline. Record decisions in [DECISIONS_AND_IDEAS.md](DECISIONS_AND_IDEAS.md).

## Definition of done per branch

1. The authorized behavior and dependencies are clear; the work record has
   realistic dates, estimate, checkboxes, and measured time under the local guide.
2. Relevant source rules, agreed contract, typed states and failure behavior
   match; unsupported backend capabilities stay unavailable.
3. Appropriate automated checks and needed device/cross-role acceptance pass.
   Unverified environments and existing failures are disclosed accurately.
4. Docs reflect the resulting behavior; diff/private-file review passes.
5. Completed, verified work is saved in meaningful local commits on the task
   branch. Group related changes by purpose, keep necessary docs/tests together,
   and inspect staged scope/privacy before each commit. Simple work may need
   only one commit; do not manufacture arbitrary splits. The user handles every
   push. Report the branch, commits and checks; a local commit is not a deployed,
   published or merged result. Follow the root `AGENTS.md` Git workflow.

## Demonstration script

Use approved synthetic test accounts and genuine role actions:

1. Buyer creates a shop order; seller prepares and marks it ready in the web app.
2. Rider signs in on the phone, claims, scans the seller waybill, and confirms
   pickup; origin handler receives it in the web app.
3. Logistics moves it through the mandatory Mother-Hub route to destination.
   The destination handler assigns the final-mile rider.
4. Assigned rider scans out, records genuine test proof and exact test COD.
   Buyer confirms receipt separately; hub/platform show separate remittance
   and reconciliation before seller settlement eligibility.
5. On a second test parcel, show a failed attempt, hub return and approved retry
   or RTS. Show duplicate/stale request rejection with no invented state.
6. Show correct task/message/notification/history visibility and a holding or
   wrong-scope denial. Explain any features still blocked using the real evidence.

Keep real contact/KYC/payment data out of the demo and screenshots. A rehearsal
dataset is reset through an approved isolated setup, never a public operational
simulator. Preserve genuine custody/evidence during the rehearsed transaction.
