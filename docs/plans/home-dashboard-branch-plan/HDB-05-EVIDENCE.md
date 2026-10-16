# HDB-05 native acceptance and website handoff

October 16, 2026. Branch `feat/home-duty-claim-acceptance` starts from merged
mobile `main` `179a1ce`. Only [HDB-05](05-home-duty-claim-acceptance.md) is active.
Scanning, delivery, Trips, Messages and cash remain separate deliveries.

## Current result

**Controlled native Azure duty/claim acceptance and the website post-check
passed. The approved local build configuration now enables duty and claims.**
The native observation was
October 16 at 04:09:30 UTC (12:09:30 Asia/Manila). A virtual Linux display kept
the test window off the user's desktop. No physical phone acceptance is claimed.

The backend owner supplied dated deployed-source, migration and isolated-resource
evidence before any operational write. The native client then signed in with
the designated existing rider, switched duty off and on, claimed only the
designated ready-for-pickup parcel and verified its freshly authorized detail.
The parcel is assigned for pickup while recorded custody remains seller and
the commercial order remains ready for pickup. No collection or hub receipt
was performed.

The sanitized result, original UUIDs and safe server request references were
saved privately for the backend maintainer. Real actor/parcel identifiers,
sign-in input, contacts, proof and provider configuration are excluded here.
The maintainer independently checked the actual owning website/controller at
04:41:00 UTC (12:41:00 Asia/Manila), after the native commands. All 20 checks
passed. This is fresh post-mobile evidence, separate from preparation.

## Deployment and source evidence

- The owner's readiness observation at 03:49:59 UTC identifies running Azure
  revision `c2624735c31434aae38a2d438ab7bed2f39a464d`. Host and PHP-container
  checkouts match, the tracked checkout is clean, the actual application mount
  points there and ten relevant source files match committed contents.
- The running revision has 75 applied migrations, none pending, and all 25
  checked operational tables. The command migration, actor/key unique
  constraint and deferred actor foreign key are present. Native Home, duty,
  available jobs, claim and owned-command routes are registered.
- The owner designated an approved, placed, eligible rider and one isolated
  unassigned parcel, prepared through normal commercial workflows. Its repeated
  preparation preserved the same unclaimed parcel and existing work. These are
  owner-provided deployment/resource facts, not Flutter deployment operations.
- Mobile review began against backend `beda044`; resumption reviewed clean main
  `4b9f610`, including current operations controllers, task/command/domain
  services, contract and tests. The local source is newer than the deployed
  revision. No backend source, checkout, migrations or database was changed by
  this mobile work. The native acceptance used the deployed service.
- Existing HDB-01 recovery, account/version guards, protected account-scoped
  command storage and selected backlog prerequisites remain the foundation.
  This slice does not complete the broad M05/M06 or later acceptance cards.

## Actual native checks

| Check | Observed result |
|---|---|
| Fresh approved sign-in | Exact designated account and `operations_api_version: 1`. |
| Home and queues | Home and all three first pages decoded. One existing owned pickup detail reauthorized; the final-mile queue was empty. |
| Explicit duty | Saved false, then true, using separate persisted UUID intents and JSON Booleans. |
| Off-duty preservation | `OFF_DUTY` blocks claims; existing pickup/final-mile work remains unchanged. |
| Claim | Refreshed the designated preview/version before claiming that parcel only; fresh owned detail and queue show its assignment. |
| Original-key replay | Duty-off and claim return `replayed: true` with their identical original small results. |
| Uncertain result | Locally suppressed one real successful claim reply, verified the original intent in native protected storage, reconstructed the repository and reconciled that UUID through the owned-command endpoint. |
| Changed intent | Changed duty body with the original duty-on key returns 409 `IDEMPOTENCY_CONFLICT`. |
| Stale version | A deliberately separate, retained negative probe with the original preview version returns 409 `STALE_RESOURCE`; it does not create another assignment. |
| Existing work | Active pickups increase from two to three. The other two preserve their IDs, versions, assignment references and custody states. |
| Assignment boundary | `assigned_pickup`, order `ready_for_pickup`, seller custody, `held_by_me: false`, no custody hub. |
| Privacy/session | Operational responses are private/no-store JSON, `Pragma: no-cache`, and nosniff. Only the temporary test session is logged out; credential input is removed afterward. |

The response suppression is **local fault injection after a real server commit**.
It is not an observed network outage, process-kill test or physical-device result.
Two-rider simultaneous competition was not exercised. The website owner confirmed
one original assignment checkpoint and absent physical collection/hub receipt
from its own records. Its saved three command keys and assignment reference match
the private native receipt exactly; the rejected stale probe has no command row.

## Website confirmation and activation review

The independent read-only transaction and existing Courier/Deliveries controller
confirmed saved duty on, the same owned pickup, exactly one original assignment,
unchanged other two pickups, seller custody and ready-for-pickup commercial state.
The final-mile queue remains empty; no collection, hub receipt, delivery,
completion or cash event was added. Website preservation checks used existing
timestamps/checkpoints/queue membership; native checks separately compared the
original other-task versions. Neither maintainer reset or repeated the claim.

The review accepts **only duty and pickup-claim activation for the current Azure
build profile**. The existing ignored project-local map configuration sets
`OPERATIONS_WRITES_VERIFIED: true`; the provider key is unchanged. The shared
configuration default stays false, other environments require their own
acceptance and `HANDOVER_WRITES_VERIFIED` stays false. A fresh approved v1 session,
Home capability, placement, capacity, durable-intent and server authorization
checks still govern every command. Enabling this profile starts no tracking and
adds no automatic domain write.

The selected controlled single-rider workflow is accepted; simultaneous
two-rider contention remains separate broader API acceptance. Physical Android,
scanning, parcel outcomes and finance retain their own later acceptance. The
read-only website owner reported 20/20 checks; mobile did not independently
deploy, rerun that transaction or test browser rendering.

The first live-read attempt rejected valid headers because its test demanded
`no-cache` specifically inside Cache-Control. The backend contract uses
`Cache-Control: no-store, private` plus `Pragma: no-cache`. The adapter now accepts
that contract and audits operational routes separately from account discovery.
The corrected native read test passes; no server privacy control was weakened.

## Local implementation and verification

Review found that committed duty results previously cleared the protected intent
whenever `on_duty` was Boolean, even if it disagreed with the requested value.
The repository now requires agreement. A mismatched result retains the original
key and desired state for reconciliation rather than reporting success.

Two regressions, for desired true and false, failed against the previous code.
After correction they retain their intent through a mismatched command read and
clear it only after a matching result. Each verifies one PATCH and original-UUID
reconciliation.

- Selected contract, transport and Home recovery suites: **26 tests passed**.
- Full static analysis including both live adapters: **no issues found**.
- Native Azure read adapter: **1 test passed**.
- Native Azure controlled duty/claim adapter: **1 test passed**, including native
  protected intent storage, real HTTP and explicit same-key recovery/replay.

Before activation, the full headless suite had **350 tests passed**, with four expected skips (three
opt-in visual checks and the explicit alternate-API configuration case).
Ordinary configured **Linux release** and **Android ARM64 debug APK** builds
initially passed with domain-write gates disabled. The Android build emitted an installed
SDK XML-version warning and still completed successfully.
None of these checks accepts Android permissions, camera, GPS, minimized service
updates or screen-off navigation.

Final activation verification adds
[two build-profile regressions](../../../test/operations_activation_test.dart).
With the default disabled profile they send no writes. With the operations flag
enabled, the actual duty widget persists the requested Boolean while preserving
owned work; the claim controller sends the retained preview version and opens
fresh owned detail only after confirmation. The final enabled-profile full suite
passes **352 tests**, with the same four expected skips. The default-profile
activation suite also passes **2 tests**, and full analysis is clean. All these
responses are isolated test data; activation verification does not repeat any
live duty or claim command.

The ordinary configured **Linux release** and **Android ARM64 debug APK** were
both rebuilt successfully with the accepted flag true. No app window was opened
for activation verification and no live command was repeated.

## Opt-in acceptance adapters

The [read adapter](../../../integration_test/operations_live_read_test.dart)
uses an isolated memory token and a journal that refuses domain writes. The
[controlled write adapter](../../../integration_test/operations_live_claim_test.dart)
uses the production repository, transport and native protected journal. No
ordinary app route, automatic login or alternate production API was introduced.

Both take `BAGOO_LIVE_OPERATIONS_CASE` from the process environment, pointing to
a mode-600 JSON file in a mode-700 directory outside Git. Credentials are runtime
input, never compile-time definitions. The read input needs `account_id`, `email`
and `password`. The controlled write input additionally requires:

| Fields | Purpose |
|---|---|
| `writes_authorized`, `migrations_verified` | Explicitly true after owner verification. |
| `deployed_revision`, `deployment_verified_at` | Actual running commit and dated observation. |
| `case_marker`, `company_id`, `hub_id` | Bind the receipt and verify current placement. |
| `parcel_id`, `task_id`, `tracking`, `order` | Exact authorized isolated target; IDs remain strings. |
| `initial_duty`, `initial_pickup_count` | Confirm unchanged preflight before the first command. |
| `expected_stage`, `expected_status`, `expected_custody` | Confirm unassigned, ready-for-pickup, seller-held preview. |

Receipts persist original step UUID/body before dispatch, refuse unrelated
pending intents and reconcile saved steps on rerun. They are private, contain no
credentials or contacts, and must be preserved after interrupted checks. Do not
delete them to obtain a fresh claim key or reset the parcel to rerun acceptance.

From the repository root, with the private runtime environment already set:

```sh
flutter test --no-pub integration_test/operations_live_read_test.dart -d linux --dart-define=LIVE_OPERATIONS_READ_CHECK=true --reporter expanded
```

```sh
flutter test --no-pub integration_test/operations_live_claim_test.dart -d linux --dart-define=LIVE_DUTY_CLAIM_CHECK=true --dart-define=OPERATIONS_WRITES_VERIFIED=true --reporter expanded
```

The read check requires both write flags false; the controlled check explicitly
enables only operations. Both are skipped without opt-in. Neither needs map keys.
These are controlled acceptance tools, not instructions to repeat live writes.

## Use the accepted local configuration

From the Rider Mobile repository root, start the PC phone frame with:

```sh
flutter run -d linux --debug --dart-define=DEVICE_PREVIEW=true --dart-define-from-file=.env.geoapify.json
```

Sign in normally, refresh Home and use the duty control. Eligible available
pickups expose Claim pickup; a successful claim refreshes owned detail. These
actions change real assignments. The completed isolated acceptance parcel is
already in My pickups and must not be claimed or reset again for this check.
Seller/hub stops still have no native coordinates and keep their address fallback.

The configured ordinary Linux/Android builds must be rebuilt for this flag.
The map configuration is private and untracked; pushing this branch does not
distribute its key or enable writes in another developer's configuration.

## Later acceptance

Keep physical scanning, delivery, cash, simultaneous competing-rider and actual
Android/GPS checks in their selected later work. No extra API, provider key,
backend push or deployment is needed for this accepted duty/claim profile.

See [the API checklist](../../api/HOME_DASHBOARD_NEEDS.md#api-h02),
[deployment gate](../native-operations/DEPLOYMENT_GATE.md),
[setup](../home-dashboard-navigation/SETUP_AND_ACCEPTANCE.md) and
[acceptance matrix](ACCEPTANCE.md). This record accepts the HDB-05 workflow;
it does not complete the wider five-batch plan, M05/M06 or Android acceptance.
