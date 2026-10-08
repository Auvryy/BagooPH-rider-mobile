# Rider account settings API handoff

Backend source reviewed at `1dba047937b5f9c864112407586de4d1051f30db` (Settings API merged into main).
The [backend owner's version 1 contract](https://github.com/Auvryy/BagooPH/blob/1dba047937b5f9c864112407586de4d1051f30db/docs/api/RIDER_SETTINGS_API.md) governs the paths, JSON,
permissions and errors below. This document began as the mobile proposal and
now records the matching Flutter consumer contract. Website source was read only.

Azure deployment is still being prepared. Source review and local Flutter tests
prove consumer alignment, not deployed Settings availability or real saves.
Flutter stays on the ordinary Azure account build and enables native Settings
only after the server advertises the supported version for an eligible account.
Website cookies/Inertia pages are not used as native APIs.

## Required website behavior

- Reuse the courier profile, `ProfileInputService`, `AccountEmailService`,
  `AccountSettingsService` and reviewed-identity policies.
- The approved name and original sign-in email are read-only. Ordinary contact
  editing changes the phone only; identity corrections use the existing reviewed
  website workflow. Company, hub, service area, vehicle and credentials stay managed.
  Derive the unchanged name from the current actor if the shared contact validator
  requires it; do not accept client-selected identity or approval fields.
- Password changes require verified original email, the correct current password
  and matching new/confirmation values between 12 and 128 characters.
- Additional email management requires current password and an emailed six-digit
  code. Limit additional addresses to five. Preserve original sign-in email,
  reject other-account addresses and allow contact/recovery only after verification.
- Choosing/removing an address must recheck ownership. Never remove the original.
  Removal retains the website's recovery/OTP invalidation policy.
- Recheck fresh role, approval, restriction and account status for every command.
  Native current-password validation must check the authenticated token owner;
  a browser-only `current_password` guard cannot be assumed to work with bearer auth.

## Accepted version and routes

Advertise `settings_api_version: 1` in accepted `/rider/me` and login account JSON
**only when this entire version is deployed**. Version advertising also requires
the contact-revision migration and email registry to be installed; missing schema
returns 503 and does not advertise the version. Flutter keeps native mutations
unavailable when this field is absent or unsupported. Add narrow settings token
abilities; older account-only tokens must sign in again rather than gain authority
silently. Preserve password-fingerprint, expiry and restriction invalidation.

All paths are relative to `/api/v1`, use the current native bearer and return
private `no-store` JSON with no redirects.

| Method / path | Body | Confirmed result |
|---|---|---|
| GET `rider/settings` | None | Own settings snapshot below |
| PATCH `rider/settings/profile` | `phone` (string or null), `revision` | Fresh settings snapshot with canonical saved phone |
| PUT `rider/settings/password` | `current_password`, `password`, `password_confirmation` | `data.password_changed: true`, `data.reauthentication_required: true` |
| POST `rider/settings/emails/send` | `email`, `current_password` | `success: true`, `message`, integer `cooldown`, integer `expires_in` |
| POST `rider/settings/emails/confirm` | `email`, `current_password`, `code` | Fresh settings snapshot |
| PATCH `rider/settings/emails/{id}/preferred` | `current_password` | Fresh settings snapshot |
| DELETE `rider/settings/emails/{id}` | `current_password` | Fresh settings snapshot |

The profile revision is an opaque 64-character lowercase hexadecimal value for
this account's contact settings. Store and return it unchanged; never calculate it.
Reject stale contact edits with 409 and preserve the current values; never let a
stale form overwrite a newer website edit. Email mutations reuse atomic ownership,
password and current capacity checks from the shared service.

Settings snapshot (synthetic example; no private document URLs):

```json
{
  "data": {
    "account_id": "7",
    "revision": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
    "profile": {
      "name": "Example Rider",
      "email": "rider@example.test",
      "email_verified": true,
      "phone": null
    },
    "capabilities": {
      "update_contact": true,
      "change_password": true,
      "manage_emails": true
    },
    "emails": [
      {
        "id": "11",
        "email": "rider@example.test",
        "is_original": true,
        "verified": true,
        "preferred": true
      }
    ],
    "managed_details": {
      "available": true,
      "company": null,
      "hub": null,
      "hub_code": null,
      "barangay": null,
      "vehicle_type": null,
      "vehicle_model": null,
      "plate_number": null,
      "fleet_status": null,
      "license_number": null,
      "registration_status": null
    }
  }
}
```

Email IDs are positive decimal strings up to `9223372036854775807`, the database's
signed 64-bit maximum. Flutter rejects malformed/out-of-range address IDs before
a request and rejects malformed snapshot revisions before allowing contact edits. Settings must match the authenticated account
ID and original email. Return exactly one original address and one preferred
address. An additional preferred address must be verified; the original may
still show verification pending. `available: false` means the managed resource is unavailable;
`available: true` with null values means the queried field is not provided.
Do not infer assignment or verification from absent data.

## Failure and session contract

- Use canonical `message` and Laravel-style `errors` arrays for 422; wrong current
  password and unverified email are field errors. Return 409 for a stale profile.
- Rate limits return 429 plus integer `cooldown` or numeric `Retry-After` seconds.
  Do not report mail delivery on a failed send; code confirmation must consume the
  challenge through the existing purpose/actor-scoped OTP service.
- Session expiry/revocation returns 401; restricted/ineligible account or missing
  native settings token authority returns 403. No mutation is allowed by stale
  client approval or capability flags.
- After confirmed password change, invalidate current and other old native
  tokens and require reauthentication. Return confirmation before the client
  clears secure storage/private routes. Never return the new password or put it
  in a URL. A lost response is an unknown result; clients must not auto-retry it.

## Deployment and live Flutter proof still needed

The schema and source contract are now available. Supply the actual deployment
revision and migration evidence, then verify own/foreign
scope, wrong roles, pending/restricted accounts, narrow token abilities, original
email immutability, reviewed identity, canonical phone validation, stale edits,
wrong current password, password lengths, unverified email, post-password old-token
denial, OTP cooldown/expiry/wrong purpose/reuse, five-address capacity and recovery
invalidation. Check that website reads see native changes and native reads see
website changes. Keep backend implementation and migrations in the website repo.

Flutter acceptance additionally needs real native profile save and refresh,
password change/re-login and email send/verify/prefer/remove against the deployed
HTTPS API. Local fake repository results do not complete this goal.

## Source-aligned client checks

The Flutter transport tests use the backend owner's synthetic version 1 JSON
example and accepted routes through the existing bearer-aware account repository.
They cover canonical phone/revision saves, exact permitted request fields, email
ID bounds, stale edits and field errors, old-token denial, failed mail and confirmed
password reauthentication. These are local contract/error-handling checks, not
real backend requests, website parity or Android acceptance. No sample app mode
or embedded real credentials are introduced.
