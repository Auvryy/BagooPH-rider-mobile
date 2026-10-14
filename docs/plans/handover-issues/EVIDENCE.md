# Handover integration evidence

Reviewed October 14, 2026. Client implementation and local verification passed.
Azure native discovery/list reads passed. Live writes, involved detail/evidence,
actual receiving-hub receipt and physical Android acceptance remain open in the
[separate checklist](LIVE_CHECKLIST.md).

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
