# Rider input-validation audit

Reviewed November 2, 2026. This is a Rider Mobile client audit; the Bagoo
website and backend were read only.

## Source and scope

- Rider started from clean `main` at `7ddbd13`, equal to `origin/main`; the work
  is on `fix/rider-input-validation-audit`.
- Bagoo source was reviewed at `c55046c` (`main`, equal to `origin/main`). The
  review covered Laravel's account password defaults, application text/contact
  validation, vehicle plate and driver-license rules, and Rider Settings
  contract. This is source evidence; it does not prove the same revision is
  deployed to Azure.
- Rider inputs reviewed: sign-in, registration and OTP; Profile/Settings;
  Home and Trips searches; Messages search/composer; company search and
  applications; cash searches and offer forms; parcel outcome and proof forms;
  handover reports/acknowledgements; and manual navigation origin entry.
- Registration already requires an explicit sex choice from current server
  options and submits the selected value with the current policy versions; no
  missing sex field was found in the current client.

## Confirmed gaps fixed

| Area | Gap | Client change |
|---|---|---|
| New passwords | Registration and Settings had different rules: Settings required 12 characters while Bagoo's `Password::defaults()` accepts 8–128 with uppercase, lowercase, a number, a symbol/punctuation character, and no category-C controls. | Added one shared Rider validator matching the inspected API rules. Login keeps its existing-password check separate. |
| Registration details | Several required profile fields only checked for non-empty values, and malformed phone, plate, or license values could advance before server rejection. | Added bounded, normalized checks matching the current application contract. Invalid plate/license values now stop before the OTP step. |
| Settings phone | Arbitrary non-empty text could be submitted and rejected by the API. | Validate Philippine mobile formats before dispatch; blank remains allowed to clear the optional contact. |
| Sign-in password | Login's API requires a password string without the Settings endpoint's 4,096-character bound. | Keep login validation required-only; use the 4,096-character bound only for current-password fields in Settings. No new-password rules are applied to sign-in. |
| Email inputs | Registration/login used a basic syntax check without a length/control bound; additional email had a 255-character bound but did not reject every hidden control. | Reuse the bounded client check; registration alone keeps its existing compatibility normalization. Strict server email validation remains authoritative. |

## Reviewed safeguards retained

The audited operational forms already constrain their inputs before dispatch:
message text and company notes have bounded safe-text rules; cash uses exact
amount parsing and server-owned recipient choices; parcel outcomes constrain
money, recipient/reason selections, and proof file type/size; handover fields
and evidence are bounded and validated; and manual route coordinates must be
inside the supported area. Searches are local or capped. Their relevant PC
page/controller tests passed, so this audit made no speculative changes there.
The server remains authoritative for writes and operational decisions.

## Verification and limits

The serial PC run passed **179 tests** across the input helpers and the
registration, Settings, Home, location, Trips, Messages, company, cash, parcel,
handover, and navigation page suites. `flutter analyze --no-pub` reported no
issues; `dart format --output=none --set-exit-if-changed` found no formatting
changes; `git diff --check` passed.

These checks used Flutter's PC test environment. No connected phone, ADB,
emulator, app window, live password/contact write, or Azure deployment check was
used. Physical Android acceptance and confirmation of the deployed backend
revision remain separate.
