# Verification and documentation assessment

## Readiness is evidenced behavior

This docs branch improves the plan. It does not add runtime features, deploy an
API, run native camera checks, or repair backend failures. The starter's previous
Flutter analysis/Linux/web builds are historical evidence for the starter only.
Record new verification when each implementation slice is completed.

## Acceptance matrix

| Area | Required positive and adverse checks | Where evidence belongs |
|---|---|---|
| Login/access | Approved courier, pending/rejected holding, unplaced/off-duty, wrong role, suspended, expired/revoked token, JSON 401 and logout state clearing | Backend API tests + mobile controller/router + staging phone |
| Privacy | Another account/company/hub/task/proof/thread denied; list/page/detail agree; no tokens/KYC/proof paths/contact leaks in JSON, logs or cache | Resource/policy tests + consumer DTO review |
| Duty | One explicit desired state; failed response does not fake a toggle; new claims stop off duty while existing actions remain | API tests + task-controller/widget checks |
| Claim | Two simultaneous riders, capacity reached, stale cancellation, wrong hub/company/barangay, one winner, no double assignment | Isolated PostgreSQL concurrency + cross-role acceptance |
| Pickup | Genuine matching/wrong/malformed waybill; correct assigned actor/phase; duplicate result; wrong hub; release before/after custody | Backend transaction tests + phone scanner + origin web intake |
| Mother-Hub route | Same/cross-region required hubs, missing manifests/parcels, scoped handlers, no direct route shortcut | Backend logistics tests + real web handoffs in staging |
| Departure | Only assigned final-mile rider and destination hub; wrong waybill/source state/actor denied | API tests + phone + destination web queue |
| Delivery proof | Actual image and recipient evidence; exact COD; wrong MIME/oversize/cancel/denial/storage failure; double tap; lost response and same-key replay | Backend proof/idempotency + mobile controller + physical Android |
| Failure/retry/RTS | Each reason, refusal, attempt 1/2/3, hub return required, no rider scheduling/returned override, seller receipt closes reverse route | Backend exception tests + phone/web cross-role |
| Suspension/recovery | Restriction during held parcel/cash, narrow data/actions, hub recovery before reassignment, no portal reopening | Policy/transaction tests + cross-role recovery |
| Money | Held/remitted/reconciled distinct; discrepancies append; final-mile earnings attribution; no settlement before buyer completion and reconciliation | Backend ledger tests + authorized mobile/web presentation |
| Messages | Phase-linked recipient, stale draft denied, own threads only, same-key send replay, last-seen boundary excludes later/unopened messages | API tests + phone list/detail/controller |
| Notifications | Durable event deduplication, own read state, safe links, side-effect failure retries without undoing custody | Backend event tests + app resume/poll/deep-link checks |
| History/date/money | Correct pagination and sort, integer centavos, unknown status, midnight Asia/Manila filtering and absent earnings | DTO/controller/widget + API filter tests |
| Device lifecycle | Permission denial/retry, low light, app background/kill, picker lost data, no late response across accounts, private draft cleanup | Physical Android and targeted integration tests |
| UX | 320–430 logical pixels, 200% text, long addresses, safe area/keyboard, labelled 48px targets, empty/error/unconfirmed state, reduced motion | Linux preview/widget checks + phone/manual review |
| Deployment | HTTPS/JSON via proxy, cache bypass, trusted IP limits, size limits, auth revocation, private storage and older client compatibility | Staging operator checks + consumer smoke tests |

A passing happy path does not replace the adverse cases. SQLite unit/service
checks help validate rules but do not prove PostgreSQL lock behavior. Use isolated
databases; never reset development or production data for tests. Existing backend
suite failures need a current baseline and an explicit disposition, not a “green”
claim inferred from selected passing tests.

## Verification commands when relevant

```sh
flutter analyze
flutter test
flutter build linux --debug
flutter build web
flutter build apk --release
git diff --check
git check-ignore 'Task Creator.md'
```

Run runtime/build commands when code/packages/platform setup change, with tests
that exercise real risks. A docs-only task needs source/contract consistency,
links, examples, date windows, privacy and diff review; rebuilding unchanged
Flutter binaries does not improve evidence. A signed Android release needs the
actual configured toolchain and protected signing material first.

Add CI with the first runtime feature: analyze + meaningful tests + compatible
build smoke check, plus backend contract checks in its repo. Keep native camera
and physical-device acceptance explicit; fixture tests cannot certify hardware.

## Before and after documentation ratings

These are engineering judgments for **documentation readiness**, not user
research, runtime scores, coverage percentages, or measured productivity.
Baseline: committed starter `36f9a57`, with a useful README but no rider docs.

| Area | Before / 10 | After / 10 | Reason and remaining limit |
|---|---:|---:|---|
| Starter onboarding/run instructions | 8 | 9 | Existing commands retained; linked plan and clear preview/device limits |
| Rider scope and authority | 2 | 9 | Actor boundaries, source hierarchy, current versus proposed state |
| Custody, failure and COD flow | 1 | 9 | Stage/evidence/owner matrix, hub recovery, buyer-only completion, separate cash |
| Flutter structure and package choices | 2 | 9 | Feature-based layers, small package set, explicit Linux/plugin constraints |
| API and integration preparation | 1 | 8 | Commands, JSON/errors, privacy, retry, rollout and reuse; executable accepted spec/API still pending |
| Schedule and acceptance | 1 | 8 | Short tasks, capacity range, dependency gates and phone/cross-role checks; availability and exact presentation date need confirmation |
| Private local work workflow | 1 | 9 | Local ignored guide, generic public instruction, verified tracking and honest time rules; clean clones need separate guide provisioning |
| Overall documentation readiness | **2** | **9** | A coherent implementation plan replaces a starter-only handoff; backend agreement and empirical verification remain |

The overall score is a weighted judgment, not the arithmetic mean of the rows.
It is below 10 because API fields/limits/expiry still require backend agreement,
capacity is unconfirmed, hardware checks have not happened, and the exact
presentation date remains a working target. Runtime readiness is unchanged by
this documentation task: Flutter remains a starter screen.

## What improves efficiency

| Previous friction | New mechanism | Practical effect |
|---|---|---|
| Each coder guesses rider permissions | Explicit stage/actor/evidence contract | Fewer incompatible screens and backend shortcuts |
| Web behavior is copied into a new service | Shared Laravel services with JSON adapters | One business-rule implementation to maintain |
| UI starts before response shape is agreed | Contract-first vertical slices and fixtures | Backend/mobile can work against the same examples |
| A timeout looks like a failed or successful delivery at random | Idempotency and command reconciliation | Defined recovery without duplicate custody/cash |
| Packages are selected without Linux/native constraints | Staged stack and adapter seams | Desktop editing stays useful; native gaps surface early |
| Late extras consume presentation time | Capacity ranges, dependency gates and deferred list | Scope decisions happen before the final rehearsal |
| Work logs conflate estimates and actual effort | Private guide with measured timers and verified writes | Trustworthy progress and estimates for the next slice |

These are expected reductions in ambiguity/rework. No percentage speedup,
memory saving, battery gain, or saved-hour total was measured. Measure future
efficiency with actual-versus-estimate, blocked days, contract changes/rework,
device performance and defects found at acceptance; do not optimize the metrics
by hiding work or changing measured time.

## Traceability

| Requirement | Owning document |
|---|---|
| Detailed rider flow adapted from web | [RIDER_FLOW.md](RIDER_FLOW.md), [SOURCES.md](SOURCES.md) |
| Efficient tech and architecture | [TECH_STACK.md](TECH_STACK.md), [ARCHITECTURE.md](ARCHITECTURE.md) |
| Low-friction future web/mobile integration | [api/CONTRACT.md](api/CONTRACT.md), [api/INTEGRATION_PLAN.md](api/INTEGRATION_PLAN.md) |
| November presentation, realistic short tasks | [DELIVERY_PLAN.md](DELIVERY_PLAN.md) |
| Detailed future cards, dependency checks and batch prompts | [SUBTASK_BACKLOG.md](SUBTASK_BACKLOG.md) |
| Optional/uncertain ideas evaluated | [DECISIONS_AND_IDEAS.md](DECISIONS_AND_IDEAS.md) |
| Private guide used for every work request | Root `AGENTS.md` and ignored local `Task Creator.md` |
| Before/after assessment and evidence | This document |

## Initial documentation verification

Documentation checks passed on October 5, 2026:

- All local links resolve across 13 public Markdown files; code fences balance
  and both JSON examples parse.
- All 12 schedule rows use valid 1–14 inclusive calendar-day windows, end by
  November 20, and sum to 130–204 estimated client hours.
- All 55 publishable files passed the local privacy scan. The local guide is
  ignored, untracked, and mode 600. Commit staging excludes that guide.
- Git whitespace checks pass. Branch changes are limited to README/ignore
  rules, rider docs and root agent instructions. The requested follow-up saves
  this work in focused local commits; the user handles publishing.
- A closing read of the backend confirms the public-tracking-only API and the
  same relevant roadmap prerequisites; no web files were edited by this task.

The acceptance matrix above remains future runtime work. No new Flutter build,
native camera, backend suite, PostgreSQL concurrency, or deployment check was
performed for this docs-only branch.

## Detailed backlog verification — October 5, 2026

The follow-up contains 180 planned cards across all 16 major areas, with 63
suggested batches, 540 implementation steps, 362 completion checks and 38
requirement-coverage rows. All feature cards remain planned; none is counted
as implemented by completing the documentation.

- The canonical JSON validates unique/sequential IDs, one batch per card,
  resolved task/coverage references, acyclic task and batch dependency graphs,
  valid effort ranges and 1–14-day tentative windows ending by November 20.
- `python tool/render_rider_backlog.py --check` confirms that the index and
  sixteen linked area pages match the catalog. Completion requires evidence;
  generated documentation does not prove backend or hardware readiness.
- Local Markdown paths/anchors, referenced web-source paths, code fences and
  both JSON examples passed checks. All publishable files passed the privacy
  scan; the local guide remains ignored, untracked and mode 600.
- The detailed forecast totals 315 client hours, with a 213–499.5-hour range.
  Delivery guidance marks the older 130–204-hour forecast as superseded and
  exposes overloaded milestone windows instead of claiming the baseline fits.
- The latest inspected web source and review limits are recorded in
  [SOURCES.md](SOURCES.md). New buyer-access behavior is represented in planned
  receipt checks. Web work was read only; native APIs and deployment are unverified.

Git whitespace checks passed. Changes cover planning docs and a standard-library
documentation renderer. Runtime code, Flutter dependencies and the backend were
not changed, so no new Flutter build or backend suite was needed for this scope.
Physical Android and cross-role operational checks remain future acceptance work.
