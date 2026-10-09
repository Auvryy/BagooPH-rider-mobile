# Connecting the rider app and web backend

## Current accepted operational handoff — October 9

The backend checkout is now clean main `1d785aa`, with implemented operational
routes, backend-owned OpenAPI and sanitized examples. The earlier route observations
below remain historical snapshots. Current Flutter integration is planned in the
separate [native operations package](../plans/native-operations/README.md), which
owns its five batch files, source review and deployment/acceptance gate.
This document continues to own cross-repository coordination, not batch progress.
No Azure revision, migration, fresh operational token or device acceptance was
verified by this documentation update.

## Dated starting point

Rechecked for major-task planning on October 5, 2026 against the web checkout at
`88ed1871e39755ae09ee233112351e42472fda30`. A read-only remote-main check matched
this commit. The earlier integration review used
`f24704f0a74162369687b8bfce976775cd58208f`. Source links navigate main and may need
repository access; this source inspection does not verify a deployed environment.

| Observation | Consequence |
|---|---|
| `routes/api.php` contains public `GET /track/{tracking_number}` only | Authenticated rider API adapters still need to be built |
| Composer declares Laravel `^13.17` and Sanctum `^4.0` | Native token configuration/trait/persistence/routes are separate work |
| No `HasApiTokens`, `createToken`, `auth:sanctum`, or personal-token migration found in reviewed app/routes/migrations | Do not promise a working mobile login from dependency presence |
| Existing courier/lifecycle services enforce many normal-path operations | Delegate API commands to them; audit gaps before exposing each command |
| Phase 0 remains partial; the current roadmap includes B01–B04 implementation evidence, including logistics eligibility | Continue backend dependency order; new resource controls do not complete restrictions/recovery or native APIs |
| Waybill input evidence, failed-attempt/return/retry, manifests, notifications and financial ledgers remain partial/missing in the roadmap | Release mobile capabilities only after their corresponding backend acceptance passes |
| Scoped normal-flow tests exist; documented full-suite failures and PostgreSQL concurrency limits remain | Re-run relevant current checks; prior web test counts are not evidence for this app |

This is a starting audit, not a second running backend roadmap. Refresh these
observations when starting an implementation slice. Do not copy historical
completion ratings into a claim of current readiness.

The October 5 detailed-backlog follow-up also inspected newer buyer-access work,
ending at local `main` revision `16b502c5381938e9a9cfb7300f176b3311511713`.
See [SOURCES.md](../SOURCES.md) for the changing-checkout context and exact limits.
B05's buyer holding and narrowly permitted owned-delivered-order receipt path
must be included in cross-role delivery checks; they do not grant general
restricted access. The inspected API routes remain public tracking only. Neither
this source read nor the backlog verifies a deployed native API or reruns backend
acceptance. The older table above stays a dated observation, not a live audit.

Use [SUBTASK_BACKLOG.md](../SUBTASK_BACKLOG.md) to select client agreement, adapter
and acceptance cards. Its external prerequisite register identifies required
backend evidence without creating backend implementation tasks or copying its
running roadmap. Review the current owner-approved contract before each slice.

## Account deployment update — October 7, 2026

The web maintainer integrated the account handoff into backend main `0132562`
and reported deploying it to Azure. Its `docs/RIDER_ACCOUNT_API.md` is the
accepted account contract. Actual HTTPS checks confirm token, own-account,
logout and registration routes. Native Flutter Linux and physical Android
checks are recorded in [AZURE_ACCOUNT_ACCESS.md](../AZURE_ACCOUNT_ACCESS.md).
This supersedes the historical absence of account APIs above; task/custody APIs
and their operational prerequisites remain separate work.

## Settings source update — October 8, 2026

Backend main `1dba047937b5f9c864112407586de4d1051f30db` implements the [owner's native Settings v1 contract](https://github.com/Auvryy/BagooPH/blob/1dba047937b5f9c864112407586de4d1051f30db/docs/api/RIDER_SETTINGS_API.md).
The source routes, response service, token/schema gates and backend test cases were
read without modifying or executing the website project. Flutter's
[consumer summary](SETTINGS_HANDOFF.md) and wire tests now follow that implementation.

Azure deployment is still being prepared. No new Settings command or live
account mutation was performed in this alignment slice. Keep settings activation
behind the server version, current account eligibility and snapshot capabilities.
After deployment, use a fresh native login to obtain the new token abilities and
complete the live phone/password/email and website-parity acceptance sequence.

## Deployed Settings update — October 9, 2026

Fresh Azure login/own-account responses advertise Settings v1. Actual native Linux
Settings loading, unchanged-contact save/reload and read-only website contact
parity now pass. Generic Settings website links are retired; reviewed-identity
correction and forgotten-password recovery keep their specific web workflows.
The user deferred private password/email mutations, and no Android phone was
connected for this slice. These gates remain open. The web source review at
`9fe5ce5` still finds no native queue, pickup-claim or Trip routes.

## Reuse points

| Backend reference | API adapter responsibility |
|---|---|
| `app/Services/Courier/CourierOperationsService.php` | Delegate scoped queries, availability, claims and authorized courier operations after current contract audit |
| `app/Services/Courier/CourierMessagingService.php` | Preserve delivery-linked authorization, phase-bound recipient and selected-thread reads |
| `app/Services/Orders/OrderLifecycleService.php` | Preserve canonical commercial gates and buyer-only completion |
| `app/Services/Logistics/OrderStateMachineService.php` | Preserve ordered custody/source-state enforcement, not another client state machine |
| `app/Services/Logistics/ProofOfDeliveryValidator.php` | Reuse and extend agreed proof validation without weaker mobile rules |
| Existing policies/shared application validators/private evidence protection | Build JSON-aware positive gates and scoped resources; separate holding/recovery permission |

Existing web controllers return Inertia pages or redirects. Create thin API
controllers and allowlisted JSON Resources; do not scrape pages, share React
components with Flutter, or copy controller business logic into new routes.
Inspect actual method signatures and tests before calling a reuse point.

## Contract ownership

The backend owns the executable API and its policies. The mobile maintainer
owns DTO decoding, controller states, platform adapters, and consumer tests.
Both agree the payload/error/capability contract for a slice before implementation.
The same person may hold both roles; ownership still identifies where a change
belongs.

The backend now owns `docs/api/rider-operations.openapi.json` and sanitized
examples for implemented operations. Future schema extensions stay in that repo
as part of a selected backend task. There is no generated Flutter client accepted
by this plan; do not create a competing full specification in the mobile repo.

Record the accepted backend contract version/commit in mobile release notes and
consumer fixtures. Keep a reviewed snapshot/reference when needed; do not
maintain two independently edited full specs. Start with hand-written Dart
DTOs; generate code only after the contract stabilizes and the output is tested.

## Sequence per vertical slice

1. **Inspect:** current backend roadmap, relevant services, source rules, existing
   clients and tests. Record a missing prerequisite before promising a date.
2. **Agree:** one screen/action, allowed/disclosed fields, auth scope, concrete
   examples, all failure responses, and the backend-owned evidence/limits.
3. **Backend adapter:** JSON-aware token/account gates, validation, scoped
   Resource, existing service call, consistent transaction/lock/idempotency.
4. **Backend checks:** success, wrong role/tenant/hub/assignment, stale state,
   duplicate request, storage failure, terminal order, and no secret leakage.
   Use isolated PostgreSQL for actual claim/lock races.
5. **Publish contract to staging:** synthetic accounts and existing role flows;
   no public simulator or fabricated operational success. Agree deploy revision.
6. **Mobile slice:** typed DTO/repository, controller states, screen, native
   adapter as needed, meaningful consumer/widget and physical-device checks.
7. **Cross-role acceptance:** a mobile action is visible in the actual web hub,
   seller/buyer/admin role that owns the next step. Verify negative cases too.
8. **Review/merge/deploy:** user-controlled publication, matching docs/capabilities,
   compatibility and rollback plan. Do not merge another developer's worktree.

Prefer small branch pairs, such as backend auth adapter + mobile login/holding,
then task reads + mobile queue, then atomic pickup + scan screen. Do not implement
all endpoints in one branch or demand a complete mobile rewrite to consume v1.
Each work record remains 1–14 calendar days; larger phases are split.

## Hosting and environment gates

Keep API routing inside the existing Laravel deployment. Use a known first-party
HTTPS origin with `/api/v1`; a new API subdomain/server is not required. Shared
services and database transactions must be identical regardless of web hostname.
Mobile tokens do not depend on browser session cookies across subdomains.

The operator verifies, in staging before release:

- Correct API routes and JSON errors through Nginx/Laravel and the existing
  Cloudflare configuration; no native request trapped by HTML login/challenge.
- Cloudflare Full (strict) with a valid origin certificate when Cloudflare
  terminates traffic; private API/proof responses explicitly bypass cache.
- Explicit trusted proxy IPs/CIDRs, correct client-IP budgets and HTTPS handling;
  no wildcard trusted forwarded headers or unauthenticated blanket API bypass.
- PHP/web server/proxy body/time limits agree with purpose-specific proof limits.
- Private proof/KYC storage and access rules, backup policy, cleanup, token
  expiry/pruning and credential separation are deployed, not only committed.
- Browser-only previews use approved CORS/CSRF behavior; native tokens remain
  first-party-only. Rate limits handle polling and retries without losing safeguards.
- Request references are observable without logging sensitive payloads. No
  raw SQL/debug HTML or sample-success response is exposed on failure.

Cloudflare's primary docs describe [Full (strict)](https://developers.cloudflare.com/ssl/origin-configuration/ssl-modes/full-strict/),
[cache-rule settings](https://developers.cloudflare.com/cache/how-to/cache-rules/settings/),
and [challenge-page limitations](https://developers.cloudflare.com/cloudflare-challenges/challenge-types/challenge-pages/).
Applying these settings is an operator task; this docs branch does not change deployment.

## Safe rollout and rollback

Use additive database/API changes first. Deploy the compatible backend and verify
staging with the current mobile fixture, then release the app. When possible,
enable new capabilities only after the backend has passed acceptance. Keep older
client versions functional for an agreed support window.

On a backend rollback, disable affected capabilities and retain schema/data that
the previous version can safely read. Do not delete accepted proof/events or
roll back custody/cash history. Backups and controlled append-only repair are
different from reverting a deployment. A client rollback must preserve command
reconciliation and account privacy.

If a required action is missing, show an accurate unavailable state and escalate
the dependency. Do not call a legacy weaker web endpoint, write status directly,
or claim an offline handoff. Deferred extras cannot take time from the accepted
core-flow gates.

## First implementation acceptance

The first useful integration is an existing approved rider signing in on a real
phone, receiving own holding/placement/duty capabilities, and reading only own
tasks through staging. Verify pending/rejected/wrong-role/suspended cases,
expired token/logout, 401 JSON instead of redirect, no private cache leakage,
and source-policy consistency before adding custody commands.

Source audit authority: [backend roadmap](https://github.com/Auvryy/BagooPH/blob/main/docs/CORE_FLOW_ROADMAP.md),
[architecture](https://github.com/Auvryy/BagooPH/blob/main/docs/ARCHITECTURE.md),
and [validation](https://github.com/Auvryy/BagooPH/blob/main/docs/CORE_FLOW_VALIDATION_AND_EDGE_CASES.md).
