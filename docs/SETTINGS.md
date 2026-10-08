# Rider profile and account settings

The Flutter settings implementation follows the courier website at reviewed
backend main `85121b5`. Website source was read only. Profile leads to Settings,
then Contact information, Email and recovery, or Privacy and security → Change
password. Full forms cover the tab bar and return to their originating page.

## Production status

The existing deployment has native login/registration but no native settings
commands. Real account changes therefore remain on the supported Rider website.
An account-only deployment makes no proposed settings request, collects no
password for an unsupported command, and provides the fixed HTTPS website
settings action. Browser navigation never includes a native token or credentials.

The [settings API handoff](api/SETTINGS_HANDOFF.md) is a proposed v1 contract.
The backend owner must implement, test and deploy it before advertising integer
`settings_api_version: 1` in the accepted own-account resource. Only then does
Flutter select its native adapter. Unsupported/absent versions stay unavailable.
This preparation does **not** prove real profile/password/email updates on Azure.

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
- Snapshot decoding checks own account/original email, capability types, email
  identity/verification/preference and explicit managed-resource availability.
  Missing managed data never becomes a fabricated assignment or credential.
- Duplicate commands are blocked. Lost/malformed mutation replies never become
  success. Stale/unknown updates require a fresh read before retry; the contact
  form shows the latest saved value while retaining its unsaved draft.
- Passwords and codes stay in form memory, clear on background/disposal and
  reset visibility. Discard confirmation protects typed drafts; session/account
  changes ignore late responses and discard scoped settings data.

## Review without changing a real account

```sh
flutter run -d linux --dart-define-from-file=config/workspace-preview.json
```

Choose **Preview Rider pages**, then **Profile → Settings**. Contact, password
and email forms use an isolated memory repository. Sample email code is displayed
in that preview; no mail, account, native token or real password is changed.
The preview does not override authentication and is excluded from release entry
points. Normal native launches still connect to the deployed account API.

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
