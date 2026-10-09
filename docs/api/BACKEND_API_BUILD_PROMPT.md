# Build the Bagoo Rider native API roadmap and implementation

You own the Bagoo web/backend. Build the native API needed by the Rider Flutter app, using the same application services, records and business rules as the website. Produce one comprehensive roadmap and deliver it in working batches so the mobile maintainer can integrate each batch without requesting an endpoint for every screen.

## Ownership and current facts

- Work in the `bagoo` backend repository. Its sibling `BagooPH-rider-mobile` repository is a read-only requirements and consumer reference. Do not change Flutter files, switch its branch, or copy client business logic into the backend.
- Read your own repository instructions before editing. Preserve unrelated work and existing commits. Isolate the API work on an appropriate branch/worktree if the current checkout contains another task; do not discard or mix that work. Make focused local commits and follow the user's existing publication/deployment authorization.
- This handoff's source observation was made October 9, 2026. The backend checkout had advanced to `8c6fb63` on an active finance branch with documentation changes. This is neither a main-merge claim nor a deployed revision. Recheck the current source, tests and deployment before relying on it.
- Native account access, verified registration and Settings v1 already exist under `/api/v1`. Azure account/Settings reads and native Linux contact save/reload with website contact parity passed. Preserve these APIs and their secure-session behavior. Password/email mutations and physical Android Settings acceptance remain separate checks.
- In the inspected `routes/api.php`, native Home queues, pickup claims, Trips, messaging, notifications and operational cash APIs were absent. Existing services and web routes may already implement much of their behavior. Audit the latest checkout rather than treating an old roadmap's gap list as current evidence.
- Flutter has real account access and page/controller foundations. Its Home/Trips/Messages provider still uses explicit unavailable resources. Layouts and synthetic tests are not operational integration.
- The product has a roughly one-month development constraint and a November 21, 2026 presentation target, with development complete by November 20. Plan a feasible core delivery and name deferred work honestly; do not promise that the entire future catalogue fits that window.

## Read the authoritative material first

Backend references, relative to `bagoo`:

- `docs/README.md`, `docs/CORE_FLOW_ROADMAP.md`, `docs/CORE_FLOW_VALIDATION_AND_EDGE_CASES.md`.
- `docs/COURIER_FLOW.md`, `docs/SORTING_CENTER_LOGISTICS_FLOW.md`, and relevant buyer, seller, logistics, hub, admin, notifications and finance contracts.
- `docs/RIDER_ACCOUNT_API.md`, `docs/api/RIDER_SETTINGS_API.md`, `routes/api.php`, relevant web routes, policies, validators, models, migrations and tests.
- Inspect the current methods and tests of `CourierOperationsService`, `CourierMessagingService`, `OrderLifecycleService`, `OrderStateMachineService`, `WaybillScanInputService`, `ProofOfDeliveryValidator`, pickup/recovery/return/manifest services, notification services, and `CodCashService`/`CodCashViewService`. Service files existing does not prove the entire workflow is ready.

Rider references, relative to `BagooPH-rider-mobile`:

- `docs/PRODUCT_SCOPE.md`, `docs/RIDER_FLOW.md`, `docs/FEATURE_DIRECTION.md`, `docs/DELIVERY_PLAN.md`.
- `docs/api/CONTRACT.md`, `docs/api/INTEGRATION_PLAN.md`, `docs/api/WORKSPACE_HANDOFF.md`, `docs/api/SETTINGS_HANDOFF.md`.
- `docs/TASK_TRACKING.md`, `docs/SUBTASK_BACKLOG.md`, relevant page models and repositories under `lib/features`.

The web's approved business contracts and current verified shared behavior govern. Mobile route names, DTO examples, limits and idempotency details are proposals unless already accepted by the backend. Some documents contain dated observations or historical onboarding recommendations; account registration and Settings have since progressed. Record conflicts and choose one current authoritative contract. Do not implement competing routes just because two proposals use different names.

## Deliver the roadmap and begin useful implementation

First publish a backend-owned native API roadmap covering all groups below. For each capability, record: existing shared implementation, actual readiness/tests, required JSON adapter, dependencies, priority, estimate, and whether it is implemented, verified locally, deployed/verified, or planned/blocked. Reuse an existing API where it already supplies the needed information.

Then implement the earliest unblocked core batch. Continue batch by batch within the authorized backend scope; do not stop at a plan, create every future task automatically, or expose unfinished domain behavior as a successful endpoint. Resolve routine technical choices yourself. Ask only when an actual business/scope decision cannot be resolved from the authoritative project material. Report precise blockers and continue independent work.

Use these delivery groups; adjust dependency ordering to the current backend roadmap:

1. Shared contract, operational eligibility/duty, scoped Home queues, task detail and atomic seller-pickup claims.
2. Waybill-verified pickup, assigned hub departure and delivery outcomes; gated failure/return/recovery integration.
3. Scoped Trips/history and permitted evidence reads. Read-only history may ship earlier once its attribution is correct.
4. Phase-linked messaging and durable notifications.
5. Rider COD/remittance visibility and confirmed earnings, only against ready finance services.
6. Conditional future capabilities: personal parcel-location tags, authorized doorstep instructions and native recovery/onboarding extensions where approved.

Do not build a new API server, a separate courier business engine, or an API for every visual component. Stop Mode, responsive layouts, camera/scanner interfaces and ordinary external directions mostly consume shared task data; they do not each require a new backend system.

## Preserve the business rules

- Pickup and final-mile are assignment phases of one `courier` role. Role, approval, age eligibility, restriction, placement, duty, capacity and parcel authority are separate server checks.
- The rider claims an eligible seller pickup atomically. The destination hub/logistics operator assigns final-mile work. No mobile command may self-assign another rider's delivery or approve/place the current user.
- Going off duty prevents new work while preserving authorized existing responsibilities. Suspension requires the established narrow custody/cash recovery policy; neither a valid token nor a recovery endpoint restores ordinary authority.
- Preserve seller readiness, company/origin-hub scope, capacity and current assignment/source-state checks. The API returns limits and eligibility; Flutter must not hardcode them or send a trusted owner/company/hub override.
- Claiming is assignment, not physical collection. Seller handoff requires the accepted parcel/waybill evidence. Pickup ends only on the expected origin hub's authenticated intake. The rider cannot acknowledge that hub's receipt.
- Preserve mandatory Mother-Hub routing, including same-region routing and the required cross-region checkpoints. Facility scans, manifests and counter release belong to their existing roles.
- Only the assigned final-mile rider performs authorized departure/outcome actions. Rider delivery and buyer order completion remain separate. The rider cannot call buyer completion or seller return receipt.
- Failures, attempts, return custody, retries, reassignment and return-to-sender follow the current shared workflow. The rider cannot increment attempt counts, independently schedule retries, bypass hub-return intake or set a parcel to RETURNED.
- COD collection, held cash, remittance, reconciliation, seller settlement and rider earnings are distinct facts. No rider command can confirm another party's receipt or reconcile a financial ledger.

If a required shared rule is missing or inconsistent, fix it in the shared backend layer with both website/API regression coverage when it is within this task's authorized scope. Otherwise keep the dependent capability unavailable and document the prerequisite. Never create a weaker native-only path.

## Capability coverage

### A. Home, duty, queues and task detail — first implementation batch

Supply eligible available seller pickups, own active pickups and hub-assigned final-mile work. Include authoritative counts, duty state, placement/eligibility context, capacity, assignment phase, commercial status, operational stage, current custody/next stop, freshness/version and permitted actions with meaningful denial reasons.

Return only the disclosure allowed at that stage. An available pickup preview does not grant access to buyer contact, exact private destination or unrelated payment information. Assignment and contact visibility must be rechecked after claim/reassignment.

Support an explicit desired duty boolean, not an ambiguous toggle. Implement atomic pickup claim through the current shared transaction/locking service. One concurrent claimant wins; cancellation, ineligible placement, off-duty state, capacity and phase conflicts must not create an assignment. Provide fresh owned-task reads and an agreed way to reconcile an uncertain claim response.

A pre-custody release/cancellation command exists only if the shared release/recovery policy is implemented. Return authoritative state and checkpoint/assignment facts, not a generic success flag detached from the committed operation.

### B. Parcel work, proof, exceptions and recovery

Expose distinct authorized commands for seller pickup, assigned final-mile scan-out, delivery and permitted failure reporting. Do not expose a generic client-selected status setter.

Validate submitted waybill input through the shared normalization/exact-match rules, current assignment, phase, expected hub/stop, source state and custody. Stored tracking numbers filled in by the server are not proof that a rider scanned the matching parcel.

Agree genuine proof/recipient evidence, exact COD acknowledgment and purpose-specific upload limits. COD delivery requires its real collection/ledger guards even if the cash screen ships later; do not bypass a financial prerequisite to enable the delivery endpoint. Validate actual file content, immutable outcome evidence and private access. A preview, upload success or duplicate request alone must not report completed delivery.

Return allowed failure reasons, evidence requirements, recorded attempt facts and the correct return/recovery instruction. Retry/RTS decisions, intake and reassignment stay with the existing owning actors. Where the domain prerequisites are unfinished, return truthful capabilities and keep dependent commands disabled.

Historical/scoped proof retrieval must revalidate permission and retention rules. Never return KYC/POD storage paths or permanent public file URLs in ordinary parcel/profile JSON.

### C. Trips and history

Provide scoped list/detail, agreed search/payment/Asia-Manila date filters, real pagination and recorded checkpoints. Define pickup/final-mile attribution explicitly: historical access cannot depend solely on a mutable current courier ID that is overwritten on reassignment.

Separate delivery from buyer completion, cash collection from remittance, and recorded earnings from estimates. Missing time/proof/payment/cash facts remain unknown. Return stable sort and ownership-safe detail; never expose another courier's history through a guessable child ID.

### D. Messages and notifications

Reuse delivery/phase-linked messaging. Derive the participant from current authorized assignment and phase; do not accept an arbitrary recipient. Define list/thread/history, sending permission, unread counts, stable message IDs, limits and stale-assignment/phase errors. An obsolete draft must never be silently redirected to a new participant.

Read acknowledgment covers the exact message boundary actually displayed in the selected thread/phase. Idempotent acknowledgment must not mark another thread or newer unseen messages read. Sending must return the committed message and safe retry behavior.

Notifications come from durable backend events/records, not client polling or fake rows. Produce them only for committed domain events and preserve duplicate/after-commit protections. Scope list/read/read-through actions and destinations; reauthorize the linked resource when opened. Agree polling/refresh budgets. Push-device registration or a new provider is conditional work, not an automatic dependency of a native notification inbox.

### E. Cash, remittance and earnings

Audit the current finance work and reuse its authoritative ledger/services. Provide permitted held/remitted/discrepancy/reconciled facts and confirmed rider earnings with their provenance. Model amounts exactly in integer PHP centavos or another explicitly agreed exact representation; never float arithmetic or COD-as-earnings.

Expose a rider remittance initiation only when the existing workflow permits it. Hub/cash-handler receipt and platform reconciliation remain separate authenticated actions. Validate evidence, amount, current holder/scope and duplicate effects under locks. Show missing/unreconciled facts truthfully. New payouts, withdrawals and seller/admin financial authority are outside the Rider API baseline.

### F. Existing accounts and conditional future features

Preserve current login/logout, registration, holding and Settings APIs. Managed profile facts already supplied by Settings need no duplicate endpoint solely for a new screen. Preserve private documents, current-password checks, original-email immutability, verified additional addresses and token invalidation after password change.

Plan narrow native reviewed-identity/KYC resubmission, original-email verification or forgotten-password flows only if the product explicitly chooses them. They may submit/read their own review workflow, never self-approve or overwrite reviewed identity. Keep their current supported website workflows until a native contract is ready.

For Stop Mode and Doorstep Guide, expose the current authorized stop, frozen destination and permitted instructions/contact facts through task detail. Do not fabricate coordinates, rewrite checkout addresses or reveal instructions to an unassigned actor.

For Parcel Finder, decide explicitly whether personal compartment/location tags are device-only or server-backed. Server tags must be own-account/current-parcel scoped, phase/assignment aware, clear stale visibility and never replace the waybill, custody or other authoritative parcel facts. Mark this decision and its effort separately.

Exclude live GPS, automatic ETA, AI dispatch, route optimization, nationwide infrastructure, offline success queues, new role conversion and other unapproved expansion.

## One explicit native wire contract

Create a backend-owned API specification and sanitized examples before making Flutter depend on new shapes. Publish executable OpenAPI for implemented operations, and clearly mark future/proposed operations in the roadmap. Include a consumer route/method/body/response map; resolve conflicting proposed paths once.

- Preserve existing account/Settings response shapes and Settings version 1. New operational versions/capabilities are additive and separate; advertise them only when their implementation and required schema are available. Public masked tracking is not an authenticated Rider resource.
- Use the existing HTTPS `/api/v1` deployment and native bearer authentication. Success and failures are appropriate JSON with private no-store headers, no HTML/CSRF/Inertia dependency, no auth redirect and no secret-bearing URLs.
- Extend the existing narrow token abilities, expiry, password fingerprint and restriction checks. Existing account-only tokens must sign in again for new authority; never silently grant operations or break existing logout/holding access. Revalidate fresh account, role, placement, assignment and source state for every command.
- IDs are strings. Validate their agreed syntax/range before lookup and scope all parent/child resources. Keep commercial status, assignment phase, operational stage and custody distinct; document mappings rather than rewriting persisted statuses casually.
- Define exact money, UTC timestamps, Manila local-day filters, null/unavailable semantics, known/unknown enums, versions, stable sort and bounded pagination. Pagination/file URLs must not redirect a native bearer to another origin. Empty, denied, unavailable and failed reads are different responses.
- Allowed actions/capabilities are UI hints, not authority. Return action-specific prerequisites/limits without making the client infer permission from names or missing fields.
- Agree stable error codes/messages and field errors, including 401 session loss, appropriate 403/404 disclosure, stale/conflicting 409, validation 422, rate-limited 429 with bounded retry/cooldown, and genuine dependency/service failure. An unavailable feature must not return fabricated 200 data.
- Separate a safe correlation/request ID from idempotency. Define actor-scoped idempotency keys, payload fingerprints, transaction/uniqueness/locking behavior, same-intent replay, changed-payload conflicts, in-progress/expired handling and owned command-result reconciliation. A timeout/app restart must not produce duplicate assignments, proof, messages or ledger effects. Never blindly retry an unknown financial/custody result.
- Reject client attempts to override owner, role, approval, company/hub assignment, attempt count, ledger state, timestamps or private evidence paths. Redact passwords, tokens, OTPs, document bodies and customer data from logs/examples.

## Evidence required for each implemented batch

Run targeted backend unit/feature/contract tests and appropriate existing website regression checks. Cover wrong role, pending/restricted/unplaced/off-duty actors, expired/revoked/old-ability tokens, own/foreign resources, phase changes/reassignment, forged/malformed/overflow IDs, forbidden fields, stale versions, wrong waybills, invalid/private proof, exact cash and rate limits.

Add duplicate-command, lost-response/reconciliation and actual concurrent-claim/outcome tests. PostgreSQL concurrency evidence requires the supported test database and independent connections/processes; an in-memory SQLite pass is not equivalent. Isolate test data and never reset/reseed production or the user's normal database.

Show website/native parity through the same persisted records and services. Record exact commands/results and unchanged known baseline failures; source or example fixtures alone do not prove deployment or end-to-end success.

## Deployment and the handoff I need

Use additive migrations and the established Azure deployment workflow under existing authorization. Pulling main alone does not prove migrations, build assets, worker/config refresh or deployment verification completed. Record the actual VM checkout revision, required migration/config status, HTTPS endpoint evidence and limitations. Do not invent credentials, SSH aliases or a VM path; inspect known deployment configuration and request only genuinely missing connection information. Keep secrets private.

After every batch return:

1. Source commit/branch and exact implemented capability/routes; separate pending/blocked items.
2. Accepted contract/specification path and sanitized success/empty/denied/stale/error fixtures.
3. Body fields, token abilities, capabilities, versions, filters/pagination, proof limits and command retry/reconciliation semantics.
4. Tests actually executed, concurrency/database evidence, web parity and material gaps.
5. Migration/config/deployment steps and the independently observed deployed revision or a clear not-deployed status.
6. A precise Flutter integration checklist and a bounded next batch with dependencies/effort.

The mobile maintainer then changes only Rider DTOs/adapters/controllers and verifies the real native app. Do not mark Flutter integration, physical Android behavior, real email verification or a buyer/hub/finance handoff complete on its behalf.

Start now with the current-source capability audit, the complete phased roadmap and the first unblocked Home/duty/queue/claim slice. Preserve the working account/Settings contract and existing web workflows throughout.
