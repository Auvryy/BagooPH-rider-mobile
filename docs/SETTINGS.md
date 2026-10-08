# Rider profile and account settings

The Flutter settings implementation follows the courier website at reviewed
backend Settings source `1dba047` (the earlier presentation review was `85121b5`). Website source was read only. Profile leads to Settings,
then Contact information, Email and recovery, or Privacy and security → Change
password. Full forms cover the tab bar and return to their originating page.

## Production status

Backend main now implements native Settings version 1. Its source was reviewed
read-only against the backend owner's `docs/api/RIDER_SETTINGS_API.md`; Azure
deployment is still being prepared. Until the deployed account advertises the
supported version, real account changes remain on the supported Rider website.
An account-only deployment makes no Settings request or unsupported password
collection. Browser navigation never includes a native token or credentials.

The [consumer contract](api/SETTINGS_HANDOFF.md) matches the implemented backend.
Only eligible accounts advertising integer `settings_api_version: 1` select the
native adapter. Unsupported/absent versions stay unavailable. Existing
account-only tokens require a fresh login for the new settings abilities; a
settings denial clears stale local access and offers reauthentication.
Source alignment does **not** prove real profile/password/email updates on Azure.

## Implemented client behavior

- Contact edits submit phone and the saved revision only. Reviewed name, original
  email and managed placement/vehicle records stay read-only. Identity corrections
  open the existing website review process. Confirmed saves use the returned
  server snapshot and refresh the account; rejected saves retain safe typed input.
- Password fields support password managers, paste and individual labelled
  visibility controls. New/confirmation values require 12–128 characters and
  exact matching. Verified email and server capability are prerequisites.
  Confirmed change removes secure local session/private routes and returns to
  login with a notice. An unknown password result also removes local access and
  offers reauthentication/recovery without claiming success or automatically retrying.
- Additional email flows include current password, send/resend cooldown,
  address-bound six-digit verification, choosing a verified contact address and
  confirmed removal. Original email cannot be removed. Capacity and ownership
  remain server controlled; changing an address discards its previous challenge.
- Snapshot decoding checks own account/original email, exact opaque revision
  shape, supported address-ID bounds, capability types, email
  identity/verification/preference and explicit managed-resource availability.
  Missing managed data never becomes a fabricated assignment or credential.
- Duplicate commands are blocked. Lost/malformed mutation replies never become
  success. Stale/unknown updates require a fresh read before retry; the contact
  form shows the latest saved value while retaining its unsaved draft.
- Passwords and codes stay in form memory, clear on background/disposal and
  reset visibility. Discard confirmation protects typed drafts; session/account
  changes ignore late responses and discard scoped settings data.

## Everyday live-account review

```sh
flutter run -d linux
```

For a connected Android phone, run Flutter with that device selected. Ordinary
runs and debug APKs use Azure, and the main login screen has no sample-page
button. Sign in privately, then open **Profile → Settings**. Native changes stay
unavailable until the server advertises the accepted settings version. Existing
website-management actions remain available where supported.

Contact/password/email sample repositories are used only by widget/controller
tests. These checks never send mail or change a real account. The historical
workspace-preview profile now selects Azure and no longer opens sample pages.
For real settings acceptance, wait for the backend contract to be deployed and
then verify live save/refresh, password reauthentication and email management.

## Verification and remaining acceptance

Run `flutter analyze` and `flutter test`. Local checks cover typed snapshots,
account-only gating, allowed request fields, stale/failed/duplicate saves, late
response disposal, password/session cleanup, cooldown/recipient binding,
immutable original email, preview isolation, rejected input retention, background
secret cleanup and 320/1440 widths at 200% text with simulated keyboard insets.

The opt-in native Linux preview review includes all three forms and rendered
captures. These are sample UI checks. They do not prove physical Android behavior,
email delivery, deployed native settings mutations or cross-web saved state.

Recorded October 8: analyzer clean, all 72 local tests passed (two unrelated
build-specific configuration cases skipped), 17 focused controller/transport
checks passed, and one native Linux preview review passed. A Linux release build
also passed with the preview flag deliberately enabled; sample settings/credential
markers and the preview route were absent from its AOT library, while the Azure
API address remained present. No physical Android settings check was performed.

Remaining full-goal checks require the backend's agreed/deployed settings v1:
actual native phone save reflected on the website, password change and new-password
re-login with old native token denial, additional email send/verify/prefer/remove,
and actual server validation/authorization failures. Keep those gates open until
the real environments pass; do not mark M13/M14 or this goal complete from fixtures.

## Implemented backend source review — October 8

The reviewed backend `1dba047` preserves the seven proposed routes, snapshot and
password confirmation fields. It clarifies 64-character lowercase hexadecimal
contact revisions, signed 64-bit email IDs, schema-dependent version advertising,
fresh token abilities, shared write throttles and failed-mail 503 responses.
Flutter preserves server authority and now validates these wire boundaries.

The synthetic fixture in `test/fixtures/rider_settings_v1.json` comes from the
backend owner's contract example. Its transport tests exercise actual Flutter
JSON decoding, bearer requests and controller cleanup without a live server.
The backend test source was inspected but not executed or changed. Deployment,
real native saves and website/native parity remain unverified.

Validation for this source-alignment slice: static analysis passed, all 78 local
Flutter tests passed, including six new transport/contract scenarios. The changed
Markdown links, JSON fixture equality, privacy and whitespace checks passed.
No live Azure mutation, backend test execution, Android install or physical-phone
Settings acceptance was performed in this slice.
