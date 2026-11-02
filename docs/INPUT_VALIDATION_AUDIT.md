# Rider input-validation audit

Reviewed November 2, 2026. This is a Rider Mobile client audit; the Bagoo
website and backend were read only.

## Source and scope

- Rider started from clean `main` at `7ddbd13`, equal to `origin/main`; the work
  is on `fix/rider-input-validation-audit`.
- Bagoo source was reviewed at `c55046c` (`main`, equal to `origin/main`). The
  review covered Laravel's account password defaults, application text/contact
  validation, vehicle plate and driver-license rules, Rider Settings, the
  `RegistrationDocument` file rule, Rider verification-code checks, and the
  current cash/company/handover text rules. This is source evidence; it does
  not prove the same revision is deployed to Azure.
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
| Email inputs | The basic email expression accepted malformed local/domain separators and multiple `@` characters. | Keep the 255-character/control checks, reject adjacent dots and malformed domain labels, and retain plus-addressing and internationalized domains. Strict server email validation remains authoritative. |
| Parcel and handover notes | The client rejected safe multiline notes accepted by the API, but missed some Unicode control characters and hidden markers. Recipient names used a general note rule. | Match the API's LF/CRLF note behavior, reject category-C controls, hidden markers, markup and unsafe schemes, and apply the API name rule to parcel recipients. |
| Registration documents | Picker and repository checked only file size, so empty, mislabeled or unreadable documents could be submitted. | Validate non-empty files up to 5 MiB, extension/signature agreement and image dimensions at selection and again before upload. Dimensions are read from headers without decoding image pixels. Invalid replacements preserve the current selection. |
| Verification codes | Registration UI checked length rather than six ASCII digits; the Settings repository had no equivalent preflight. | Validate exactly six ASCII digits in both forms and again in both repositories before any request. |
| Input lengths | Several fields had API/model limits but no matching keyboard limit. | Add matching limits for registration/profile fields, cash and parcel amounts, company/trip/cash search, messages and OTPs. Loaded-task and conversation search use bounded local limits; manual preview coordinates are capped at 32 characters. |

## Reviewed safeguards retained

Operational choices remain constrained by fixed enums and server-owned data.
Cash and parcel money use exact decimal grammar and integer cents, cash offers
use listed recipients, evidence fields retain their existing format limits,
and manual coordinates must remain finite, within legal ranges and inside the
supported area. The server remains authoritative for writes and operational
decisions.

## Verification and limits

The final serial PC run passed **178 tests** across the input helpers and the
registration, Settings, Home, location, Trips, Messages, company, cash, parcel,
handover, and navigation page suites, including malformed email/code/file cases,
multiline notes and the configured field limits. `flutter analyze --no-pub`
reported no issues. Formatting and `git diff --check` were clean.
After that broad run, the account input helper suite was rerun with a valid
quoted local-part address case; all **9 tests** passed.

These checks used Flutter's PC test environment. No connected phone, ADB,
emulator, app window, live password/contact write, or Azure deployment check was
used. Physical Android acceptance and confirmation of the deployed backend
revision remain separate.
