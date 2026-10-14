# Handover deployment and device checklist

This checklist owns the outstanding acceptance for the [selected integration](README.md).
The existing Geoapify key is sufficient; handover uses Bagoo's authenticated API.
Do not create substitute actors/parcels or confirm possession for a fixture.
The October 14 native Linux read check passed fresh version-1 discovery, Home
handover flags and an empty involved queue; see [evidence](EVIDENCE.md).
The account-specific and device rows below remain for the controlled real flow.

## Backend/operator information

- [ ] Confirm the running Azure Docker deployment's commit includes merged H04
  (`77fb96e` or a verified descendant). A local Git pull is not running-app evidence.
- [ ] Confirm ordinary H01–H03 migrations and the existing operations/Settings
  dependencies are applied. H04 adds no migration and needs no reset/reseed.
  Discovery checks `handover_issues`, `handover_issue_events`,
  `handover_recovery_grants` and `handover_manifest_receipts` as well as existing
  native tables; the backend's migration audit remains authoritative.
- [ ] Confirm the HTTP/proxy/PHP upload limit accepts 5 MB plus multipart overhead,
  and private original evidence is retained with its existing integrity checks.
- [ ] Identify an expressly authorized approved involved rider and test parcel,
  with an actual missed scan/evidence and owning seller/company/hub actors.
  Supply credentials privately at sign-in, not in code, docs or build flags.

## Fresh native session

- [ ] Sign out and sign in again after deployment. Account discovery must return
  `operations_api_version: 1` and `handover_api_version: 1`.
- [ ] Home must return handover version 1 and `capabilities.handover_issues: true`.
  Reporting additionally requires `handover_reporting: true`; the new token
  carries `rider:operations:handover`. Version alone does not prove permission.
- [ ] Verify involved list/detail and denied/foreign resources. Empty queues are
  valid reads and cannot establish reporting or holder acknowledgement acceptance.

## Controlled write and device acceptance

- [ ] After the deployment/session evidence is recorded, enable the separate
  `HANDOVER_WRITES_VERIFIED` build define for the authorized handover check.
  It defaults false and does not enable duty or pickup claims. Keep the provider
  key private in the existing ignored project-local configuration.
- [ ] Connect an authorized Android phone with USB debugging and verify the build
  identity before installation. Use `flutter devices` and the actual device ID.
- [ ] From Home or an owned stop, open Handover issues. Pick actual JPG/JPEG/PNG/
  WEBP/PDF up to 5 MB; verify cancellation, invalid/large files, backend field
  errors, ordinary Back and 200% text. Safe entered values remain after rejection.
- [ ] Record one actual missed scan. Verify `pending_review`, no client custody
  or hold change, one original key and actual original evidence in the web review.
- [ ] Exercise a lost response/restart on isolated authorized resources. Check
  the saved request, refresh current detail and retry only the original intent
  and bytes. Verify one report/event, conflict/expiry handling and encrypted cleanup.
- [ ] Open private image and multipage PDF evidence; verify permission loss,
  altered/missing evidence and background/resume revalidation. No public URL,
  export or bearer-bearing provider request substitutes for this read.
- [ ] Have the owning web actor independently review/authorize a named-holder
  grant. Verify receiving hub, current source/version, expiry and actor scope.
- [ ] Physically check the actual matching waybill, enter notes and explicitly
  confirm possession. Verify one `holder_acknowledged` event and a retained hold.
- [ ] Have the named hub handler record actual receipt in its web portal.
  Refresh the rider detail and confirm the real recovered state/history. The
  rider has no receiving, review or authorization API action.
- [ ] Verify account/approval/discovery loss closes private views and that normal
  account/Settings, primary navigation and existing Navigate/Stop still work.

PC phone-frame review from the Rider repository root:

```sh
flutter run -d linux --debug --dart-define=DEVICE_PREVIEW=true --dart-define-from-file=.env.geoapify.json
```

Native acceptance on a connected phone uses the same app/configuration and its
device ID. Linux render/storage checks and APK builds are recorded separately
from actual Android and cross-role acceptance.
