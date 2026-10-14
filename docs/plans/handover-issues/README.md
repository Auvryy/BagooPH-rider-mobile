# Native handover issues integration

Selected October 14, 2026. State: client implemented and locally verified on
`feat/rider-handover-issues`, from merged mobile `main` `adc2760` (PR 21).
Azure discovery and the empty involved queue passed a native read check.
Controlled writes, private live documents, actual hub receipt and Android
acceptance remain open in the [deployment/device checklist](LIVE_CHECKLIST.md).
Estimate: 12 client hours, October 14–18, due October 18 at 18:00 Asia/Manila.
This estimate excludes operator/device waiting and does not change the November
20 development deadline.

## Selected scope and authority

The backend H04 contract is merged in `77fb96e`; the reviewed owner checkout
advanced from `89c85bf` to `a1bd49f`, with unrelated company-request work preserved.
The H04 source fingerprints stayed unchanged. Read-only sources are
`docs/api/RIDER_HANDOVER_API.md`, `docs/api/rider-operations.openapi.json`,
the exercised handover examples, native service/controller and relevant tests.
The backend owns report involvement, source/version, holds, grants and custody.
The October 15 local verification extension runs the unchanged backend kernel
and existing test helpers in isolated SQLite `:memory:`. It does not edit the
backend checkout or change any development/production database, deployment or
migration state. See the [local runner](../../../tool/handover_local_api/README.md).

Add involved issue lists/detail from Home and owned Stop Mode, actual missed-scan
reporting with one private evidence file, bearer evidence viewing and the named
holder's possession acknowledgement. Keep observations separate from recorded
custody. Acknowledgement keeps the hold until actual named-hub receipt. Review,
authorization, receiving, restricted recovery sign-in, Mother Hub routing, buyer
completion and cash remain with their owning web workflows.

This selected extension relates to M01/M02 transport and intent safety,
M03 discovery, M04 entry, M08 recovery and M16 privacy/device checks. It does not
complete restricted native recovery or the original failure/return cards.
The [five-batch plan](../native-operations/README.md),
[shared consumer constraints](../native-operations/CONSUMER_RULES.md),
[backlog](../../SUBTASK_BACKLOG.md) and [source rules](../../SOURCES.md) remain
in place. Existing discovery/account/transport/Stop Mode provide partial
prerequisite evidence; new encrypted original-file retention is scoped here.

## Implementation sequence

1. Decode account/Home discovery and all five H04 methods; preserve decimal
   string IDs and integer handover versions. Extend the authenticated transport
   for bounded private bytes without redirects or bearer leakage.
2. Persist one account/API-scoped UUID intent, exact body and original file bytes
   before dispatch. Reconcile lost responses with owned command GET; retry only
   that intent. Storage failure prevents dispatch, and account changes hide it.
3. Add ordinary scrolling lists, detail, report fields, evidence view and explicit
   possession confirmation using the existing style and primary navigation.
   Refresh current detail before acknowledgement and after committed results.
4. Verify contract/controller/widget regressions, analysis and native builds;
   exercise the actual deployed API and phone when their prerequisites exist.
   The isolated local runner provides client/kernel evidence when live actors
   and a phone are unavailable; its synthetic actions cannot establish physical
   possession or deployed upload acceptance.

## Acceptance checklist

- [x] Local discovery/capability checks cover old, unavailable and denied sessions.
- [x] Involved lists paginate/deduplicate; detail distinguishes observations,
  original/current custody, history, receiving hub and permitted grants.
- [x] Client file validation and original-byte retention cover JPG/JPEG/PNG/WEBP/PDF
  up to 5 MB, including a native Linux maximum-size storage round trip;
  multipart boundaries, field errors and MIME/error decoding are covered.
- [x] Current source/version and true JSON possession confirmation are used;
  stale/expired/foreign grants cannot acknowledge from cached flags.
- [x] Local timeout/restart/unknown/conflict/expired command checks retain the original intent
  and bytes; authoritative success refreshes today's state without claiming receipt.
- [x] Resume/Back/account changes, cooldown, layouts, local regression and ordinary
  Linux/Android builds are verified and recorded in [evidence](EVIDENCE.md).
- [x] Fresh native Azure sign-in advertises operations/handover version 1; Home
  flags and an empty involved list decode through the Flutter client.
- [ ] Operator confirms the actual deployed revision and ordinary H01–H03
  migrations. Read discovery is not a complete deployment/upload audit.
- [ ] Authorized Android report, private image/PDF, lost-response recovery and
  actual hub receipt are observed; backend or build checks cannot close this row.

The user deferred Android and any unresolved Azure acceptance. No involved test
parcel or authorized live evidence/grant has been supplied; the verified rider's
involved queue was empty. `HANDOVER_WRITES_VERIFIED` defaults false, independently
of the existing duty/claim gate. Production writes remain gated until the
selected deployment and controlled-resource acceptance are recorded. The existing
Geoapify configuration is unchanged; handover needs no additional provider key.

From the Rider repository root, review the PC phone frame with real Azure login:

```sh
flutter run -d linux --debug --dart-define=DEVICE_PREVIEW=true --dart-define-from-file=.env.geoapify.json
```
