# Account compatibility watch and separate conditional branch

This is outside the selected Home bug fixes. It records relevant source changes
observed while the website developer was working; it does not modify account code
or declare a deployed signup failure. Existing approved-account Home UI fixes do
not need to wait for a new registration redesign.

## Source observations

| Item | Observed backend/mobile difference | Evidence and implication |
|---|---|---|
| Password policy | Backend commit 10619ce changes native account/Settings policy to 8–128 characters; mobile SettingsForm still validates 12–128 | Backend RIDER_ACCOUNT_API/RIDER_SETTINGS_API and password-policy commit; settings_forms.dart new-password validator. Once this source is the accepted target, the UI rejects otherwise permitted 8–11-character new passwords |
| New application sex field | RiderAuthController options advertises sex_required:true; ApplicationValidationService requires sex; mobile RegisterPage submits no sex | Source compatibility gap for new applications when that source is deployed. Do not guess a sex value or bypass the requirement |
| Owner documentation conflict | The inspected RIDER_ACCOUNT_API options paragraph still says sex_required=false while options/rules say true | Ask the API owner to resolve/update the contract and examples; this review does not rewrite website docs to pick a side |
| Vehicle profile alias | Both the backend registration enum and mobile RegisterPage allow Sedan / Van, but NavigationProfile.forVehicle recognizes only sedan or van separately | Confirmed BUG-H05, handled within HDB-02. Unknown fleet/truck/tricycle choices still require the explicit supported-profile decision |

These observations were rechecked when the backend owner merged to clean main
`b91f13a57c7fedbd0252b0d98eeefe834b160aee`. The source/docs sex mismatch remained;
The earlier working state and the final committed source are distinct from
evidence that this release was deployed to Azure.

The backend login validator itself accepts a required password string rather than
requiring the new-application minimum. Do not apply a new-password policy to an
existing sign-in password or change permanent sign-in identity/approval rules.

## Conditional delivery: ACCOUNT-COMPAT

Suggested branch: `fix/native-account-contract-alignment`. State: **conditional,
not activated**. Planning effort: **3–6 client hours** for focused contract alignment
and checks, excluding owner clarification/live mailbox/device waiting. Recommended
model/effort: **GPT-6.1 Sol / High**. Re-estimate if the current contract comparison
reveals a larger separate registration change.

Dependencies: API owner resolves current source/docs/options, the actual selected
release is identified, existing account/Settings behavior is preserved, and the
[API-H02 checklist](../../api/HOME_DASHBOARD_NEEDS.md#api-h02) is reviewed. Associations:
[M01.03](../../backlog/M01.md#m01-03), [M01.10](../../backlog/M01.md#m01-10),
[M03](../../backlog/M03.md) and
[M13](../../backlog/M13.md). These do not activate entire account/profile areas.

Scope if separately selected:

- Compare every required native application/options field and policy acknowledgement
  against the current client; limit changes to the accepted observed contract gap.
- Consume required demographic options with explicit user input. Preserve adult
  birthday, OTP, private documents, vehicle/license, holding and reviewed identity.
- Align new-password limits/requirements with the accepted policy without tightening
  existing login or changing the original sign-in email.
- Keep native Settings contact and additional-email/current-password/OTP semantics
  and account-scoped session revocation correct; no approval or role conversion.
- Keep website code/docs and its uncommitted work read only; return an exact owner
  request for any remaining contradiction instead of silently editing the backend.

Finish evidence:

- [ ] Required sex/options/policy fields are represented and submitted only after
  valid user input; missing/changed requirements show actionable errors.
- [ ] New passwords at the accepted minimum/bounds and each character rule are
  tested; valid existing sign-in credentials are not rejected by new-password rules.
- [ ] Native wire/validation tests, registration/holding and Settings regressions
  pass against accepted source fixtures, with privacy and unknown-field checks.
- [ ] Any real signup/password write uses authorized private test resources and
  source/deployment/mailbox/device evidence; no automatic production signup is implied.
- [ ] Runtime change and evidence are reviewed in this separate branch with local
  commits; the user publishes/merges it. It is not bundled into HDB-01.

The 80–137-hour HDB estimate excludes this conditional follow-up. HDB-05 must
acknowledge compatibility when creating new native applicants or testing changed
Settings policy, but can use an already authorized approved rider when supported.
