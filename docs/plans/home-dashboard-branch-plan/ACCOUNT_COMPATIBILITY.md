# Account compatibility watch and deployed-account follow-up

This is outside the selected Home bug fixes. It records relevant source changes
observed while the website developer was working; it does not modify account code
or declare a deployed signup failure. Existing approved-account Home UI fixes do
not need to wait for a new registration redesign.

## Source observations

| Item | Current contract and Rider state | Evidence and implication |
|---|---|---|
| Password policy | Bagoo `main` at `c55046c` uses 8–128 characters, mixed case, numbers, symbols/punctuation, and rejects category-C controls. The former Rider registration/Settings mismatch is fixed locally on `fix/rider-input-validation-audit`. | `AppServiceProvider`, `AccountSettingsService`, and `docs/api/RIDER_SETTINGS_API.md`; Rider `password_policy.dart` and shared form wiring. Source parity is covered by PC tests; Azure deployment and a live password change were not checked. |
| New application sex field | Bagoo `main` at `c55046c` requires sex and advertises its allowed choices. Rider options parsing requires that contract; registration requires a choice and submits it with policy versions. | `RiderAuthController`, `docs/RIDER_ACCOUNT_API.md`, `registration_options.dart`, and `RegisterPage`. No current source gap was found. Deployment acceptance remains separate. |
| Owner documentation conflict | The current `docs/RIDER_ACCOUNT_API.md` and options controller both say `sex_required=true`; the previously observed contradiction is no longer present at `c55046c`. | No owner clarification is needed for this source snapshot. |
| Vehicle profile alias | Rider navigation recognizes the registration value `Sedan / Van` as its supported drive profile. | `NavigationProfile.forVehicle` in `route_geometry.dart`. Unsupported fleet/truck/tricycle profiles still require an explicit supported-profile decision. |

The earlier observations were recorded against backend main
`b91f13a57c7fedbd0252b0d98eeefe834b160aee`. The current source recheck at
`c55046c` resolves the former sex documentation mismatch and confirms the
vehicle alias handling. The password-policy client correction is in the local
Rider audit branch. These source facts do not establish which revision is live
on Azure.

The backend login validator itself accepts a required password string rather than
requiring the new-application minimum. Do not apply a new-password policy to an
existing sign-in password or change permanent sign-in identity/approval rules.

## Client alignment and deployed-account follow-up

The current client source alignment is implemented locally on
`fix/rider-input-validation-audit`; review and merge remain user-managed. This
does not complete M03/M13/M14 or prove the deployed service has this source.
See the [input-validation audit](../../INPUT_VALIDATION_AUDIT.md) for the scoped
page review and PC evidence.

Any live acceptance still depends on identifying the Azure revision, an authorized
account/mailbox, and a safe test window. Associations: [M01.03](../../backlog/M01.md#m01-03),
[M01.10](../../backlog/M01.md#m01-10), [M03](../../backlog/M03.md) and
[M13](../../backlog/M13.md). These do not activate entire account/profile areas.

Client source alignment covered by the current branch:

- Registration consumes required server options with explicit user input and keeps
  the existing birthday, OTP, private-document, vehicle/license, holding and review
  flows intact.
- Registration and Settings share the current new-password policy. Existing login
  passwords remain outside that policy.
- Settings contact and additional-email/current-password/OTP semantics remain
  unchanged; no approval, role conversion, or wider identity edit was added.
- Bagoo source and its existing untracked audit document remain read only.

Finish evidence:

- [x] Required sex/options/policy fields are represented and submitted only after
  valid user input; missing/changed requirements show actionable errors.
- [x] New passwords at the accepted minimum/bounds and each character rule are
  tested; valid existing sign-in credentials are not rejected by new-password rules.
- [x] Registration and Settings validation regressions pass with isolated PC
  fixtures; the broader 179-test set is recorded in the audit report.
- [ ] Any real signup/password write uses authorized private test resources and
  source/deployment/mailbox/device evidence; no automatic production signup is implied.
- [x] Runtime change and evidence are reviewed in this separate branch with a
  local commit; it is not bundled into HDB-01.
- [ ] The user publishes and merges the branch.

The 80–137-hour HDB estimate excludes remaining live account acceptance. HDB-05
can use an already-authorized approved rider when supported; this audit does not
require a production signup or password change.
