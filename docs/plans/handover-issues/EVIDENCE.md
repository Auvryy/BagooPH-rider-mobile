# Handover integration evidence

Reviewed October 14, 2026. Client implementation and local verification passed.
Azure native discovery/list reads passed. Live writes, involved detail/evidence,
actual receiving-hub receipt and physical Android acceptance remain open in the
[separate checklist](LIVE_CHECKLIST.md).
The October 15 extension below adds native client/kernel flow verification with
isolated synthetic resources, following the user's instruction to proceed locally
without a phone or supplied actors.

## Source and scope

Mobile branch `feat/rider-handover-issues` starts at merged `main` `adc2760`
(Stop Mode PR 21). Backend H04 is merged in `77fb96e`; its read-only checkout
advanced from `89c85bf` to `a1bd49f` during this work. Unrelated company work was
preserved. No backend file, database, migration, deployment or live parcel write
was changed by this integration.

| Backend source | SHA-256 |
|---|---|
| `docs/api/RIDER_HANDOVER_API.md` | `c245cb940436cf0432cd94b64527dd23c46eea0f50311efc0c1abd7d05fcf259` |
| `docs/api/rider-operations.openapi.json` | `fc9da7317667a6ec0b947b7c20185b4dfe6a2d2cc7106363edab8b64972a631d` |
| `app/Services/Courier/RiderHandoverService.php` | `2ae14049725b38eba645cbd55a31fc53615125592b7fc285e138d2386fab0829` |

The [selected plan](README.md) adds five H04 methods and owned command
reconciliation. It leaves the five-batch operations plan and wider M08 cards
unchanged. Backend review, authorization and receiving stay web-owned.

## Implemented behavior and evidence

| Requirement | Implementation and verification |
|---|---|
| Discovery and current authority | Additive account/Home handover version and flags; old/denied/unavailable states cannot gain write authority. Fresh Home and grant detail precede acknowledgement. |
| Home/owned-stop entry and ordinary navigation | Full-page scrolling issue list, status filters and detail; owned stop prefills the tracking number. Ordinary Back/Escape and account changes preserve primary navigation. |
| Exact identifiers and versions | Decimal string IDs through signed 64-bit maximum; integer handover counter and unchanged source hash are distinct from task revision hashes. Pickup/manifest grant fixtures and malformed input checks passed. |
| Observations and custody | Report observations, original/current recorded custody, history, named hub, expiry, blockers and permitted grants are separate. The rider cannot review, authorize or receive a parcel. |
| Multipart original evidence | Extension/MIME/signature and 5 MB bounds; generated multipart boundary and unchanged bytes/extension. Field feedback survives authoritative refresh; safe entered values and the selected file survive rejection/cancelled replacement. |
| Durable intent and uncertain results | Account/API-scoped encrypted UUID, exact body and original bytes precede dispatch. Storage failure blocks dispatch. Timeout/restart, unknown, conflict and expiry retain the original intent. Explicit reconciliation performs one command GET and retries only that intent. |
| Possession acknowledgement | Matching actual waybill, notes, unchecked explicit possession control, current version/source and true JSON boolean. Changed, foreign, expired or unavailable grants block stale acknowledgements. |
| Current state after success | Command envelopes remain original history; fresh detail supplies today's state. Acknowledgement retains the hold. Tests show recovered state only after a later server-returned hub receipt. |
| Private evidence | Fresh involved detail; bounded same-origin bearer download without redirects or public storage URLs. JSON errors decode before rendering. Private/no-store/nosniff/MIME checks, session guards and background/resume revalidation protect the viewer. |
| Lifecycle and cooldown | No new background polling. Covered views pause reads; resume revalidates. Account/approval/discovery changes close private routes. Denials and 429 cooldowns are covered. |
| Responsive presentation | Report/list/detail and acknowledgement checked at widths 320, 390, 840 and 1440 with 100%/200% text; field feedback, 48 px targets, keyboard/Back and existing styles retained. |

The handover journal has its own protected namespace; existing duty/claim intents
are untouched. Uncertain handover intent/evidence stays encrypted through logout
for the original account/API until its outcome is known. Tokens, exported proof
files and travelled-location history are not part of this journal. Confirmed
results and definitive rejection clear it; an unknown response cannot replace it.

## Local verification

| Check | Result and limit |
|---|---|
| Dependency resolution | Passed on Flutter 3.47.1 / Dart 3.13.1. Existing versions preserved; new PDF dependencies require Flutter 3.47 or newer. |
| Dart formatting and final analysis | Clean after formatting and replacing a test-only logging lint. |
| Full Flutter suite | 348 passed, one expected configuration skip. Contract, transport, controller, widget and account-route regressions included. |
| Native Linux integration | Two passed: actual protected 5 MB journal round trip with account/API isolation and cleanup; real two-page PDF rendering with distinct pixels and viewer-ready callback. |
| Ordinary Linux release build | Passed with existing ignored map configuration and real Azure account service. |
| Ordinary ARM64 Android debug build | Passed with the same configuration; APK creation does not prove phone behavior. |

The native storage test initially exposed microsecond timestamps that the journal
decoder rejected. Serialization now uses the accepted millisecond UTC format;
the maximum-size native round trip and a focused regression passed after the fix.
These results do not substitute for an Android restart/storage/file-picker check.

`pdfrx` 2.6.5 supplies in-memory native PDF viewing, and the already locked
`crypto` 3.0.7 is now a direct dependency for original-byte integrity. Primary
package/platform/license documentation was reviewed before adding them:
[pdfrx](https://pub.dev/packages/pdfrx),
[crypto](https://pub.dev/packages/crypto). Evidence viewers use no document URL
or export action; PDF links are disabled and image caches are evicted on leaving
or backgrounding the viewer. Documents are reauthorized on resume.

Native verification command, from the Rider repository root:

```sh
flutter test --no-pub integration_test/handover_native_test.dart -d linux --reporter expanded
```

## Live Azure read check

The opt-in native Linux check passed through `ApiAuthRepository`, Home decoding
and `HandoverRepository`, using the existing authorized test rider and a separate
in-memory token. Fresh account discovery returned `operations_api_version: 1`
and `handover_api_version: 1`. Home allowed handover reading/reporting, and the
involved list returned zero issues. The temporary session was logged out; the
user's stored session was not replaced. Handover writes were disabled throughout.

```sh
flutter test --no-pub integration_test/handover_live_read_test.dart -d linux --dart-define=LIVE_HANDOVER_READ_CHECK=true --reporter expanded
```

An empty queue proves authenticated discovery/list decoding only. No involved
live detail, evidence download, report, possession event, upload-proxy limit or
actual receipt was exercised. The operator's actual running commit/migration
audit remains outstanding; read flags are partial deployment evidence.

## October 15: isolated native client and Laravel kernel

The [local runner](../../../tool/handover_local_api/README.md) passed one native
Linux integration test against the unchanged Laravel HTTP kernel. It uses the
backend's existing order/handover test helpers, a loopback-only HTTP bridge and
SQLite `:memory:`. All other database connections are removed before migrations;
files and application caches live in a temporary ignored Rider build directory
and are removed on exit. No backend checkout or existing container was changed.
The source checkout advanced to merged `main` `1327bc1`; the three H04 source
fingerprints above remained unchanged.

```sh
node tool/handover_local_api/run.mjs ../bagoo
```

Observed through actual `ApiAuthRepository`, Dio, `HandoverRepository` and native
`SecureHandoverJournal`:

- Original PNG multipart bytes survive encrypted retention, a deliberately lost
  committed response, repository recreation and owned command reconciliation.
  The server records one report and one command; original stock, order, custody
  and COD observations are unchanged by the report.
- Involved list/detail decode and private image bytes return with the expected
  response headers. The downloaded bytes and stored hash match the original.
- Independently authenticated fixture web actors review and authorize through
  existing backend helpers. Current native detail permits acknowledgement;
  the rider sends an integer version, source token and true JSON boolean. One
  holder event is recorded and the hold remains active.
- The fixture's eligible web handler records receipt through the existing
  receiving helper. Refreshed native detail then becomes recovered without a
  rider receiving command.
- A PDF interruption before dispatch produces `COMMAND_UNKNOWN`. Reconciliation
  retains its original key and retries only that intent. The private PDF bytes
  and stored hash match exactly, with two reports and three committed commands
  overall, including the single acknowledgement.
- An image with a PNG signature but unreadable contents is rejected by the real
  backend validator. The native client receives HTTP 422 evidence field feedback
  and clears only that definitively rejected intent.

Final Dart analysis, formatting, PHP/Node syntax and diff checks passed. The
ordinary product code and existing write defaults are unchanged by this test
extension. The earlier full suite and ordinary builds retain their October 14
scope; they were not rerun for these test-only additions.

The bridge uses Node's standard Fetch multipart parser and passes UploadedFiles
to Laravel's unchanged kernel. It does not certify PHP's web-server multipart
parser, Azure/proxy upload limits, PostgreSQL concurrency, Android file picking,
physical possession or real hub receipt. The fixture controls exist only in the
test runner, and the integration test is skipped outside that runner.

## Remaining acceptance

The user deferred unresolved Azure and Android checks. No phone, authorized
involved parcel, actual evidence or named-holder grant is available for the
controlled flow. `HANDOVER_WRITES_VERIFIED` remains false and does not enable
the existing `OPERATIONS_WRITES_VERIFIED` duty/claim gate. The existing private
Geoapify configuration was preserved. Local fixtures remain test-only.

The [deployment/device checklist](LIVE_CHECKLIST.md) records exactly what the
backend operator and rider must supply and observe. This client milestone does
not complete physical custody, restricted recovery, normal parcel outcomes,
Mother Hub routing, buyer delivery or cash acceptance.
