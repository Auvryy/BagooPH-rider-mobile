# Working rider account access

This slice connects login, registration, own-account home and logout to Laravel.
The server uses the same account database and courier registration service as
the Bagoo website. This home is an authenticated scaffold; parcel queues,
assignment, duty, trips and operational commands remain separate work.

The [deployed HTTPS profile and acceptance record](AZURE_ACCOUNT_ACCESS.md)
describe Azure account access. The isolated local demo below is a separate
test environment; its synthetic email inbox is not used for real deployment.

## Check the local demo

Start the backend demo and local email inbox using the instructions in the
backend's `docs/RIDER_ACCOUNT_API.md`. It uses an isolated synthetic SQLite
database and the actual Laravel web/API app. Existing PostgreSQL is untouched.

From the Flutter repository:

```sh
flutter pub get
flutter run -d linux --dart-define=API_BASE_URL=http://127.0.0.1:8089/api/v1 --dart-define=ALLOW_LOCAL_AUTH=true
```

To use Chrome without the phone frame:

```sh
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8089/api/v1 --dart-define=ALLOW_LOCAL_AUTH=true --dart-define=DEVICE_PREVIEW=false
```

The synthetic fixture is `rider@bagoo.test` / `Password1234`, matching the web
DatabaseSeeder convention. Sign in, check the actual name/email/account status,
then choose **Log out**. The server revokes the device token before local state
is cleared. An unconfirmed logout keeps the session visible for retry.

Registration uses three stages with responsive field pairs and numbered circles.
Complete the rider/contact/address fields, choose the supported vehicle and
identifiers, select actual ID/license/OR-CR images or PDF and choose a password.
Files stay in memory until submission and are limited to 5 MB each. Enter the
delivered email code, then submit. Native role/approval/assignment are server
owned. New accounts go to an authenticated **Application under review** home,
as the web application goes to holding; they are not approved by the client.

For the local demo, use a new synthetic address ending in `@bagoo.test`. View
its delivered verification message in the local inbox on loopback port 8028.
That helper accepts synthetic recipients only and is not a production mailer.
Real deployments use the existing backend's configured delivery transport.

## Sessions and environments

Normal native launches default to the deployed Azure HTTPS API and matching
Rider website. `API_BASE_URL` overrides that default and must end in `/api/v1`;
custom APIs do not inherit the production website address. Historical Home/workspace
preview flags are ignored by application routing and never disable account access.
An explicitly empty API remains a developer configuration error. Sample layouts
are confined to automated tests; ordinary APKs always target Azure unless an API
override is deliberately supplied.

`API_BASE_URL` is public configuration. Release builds
require HTTPS; requests never follow redirects with credentials. Native tokens
use `flutter_secure_storage` and the platform keyring/keystore. Storage failures
are surfaced and never fall back to plaintext.

`ALLOW_LOCAL_AUTH=true` is permitted only in a debug loopback build. It enables
an explicitly ephemeral memory session for local synthetic testing, including
the browser. Reloading this browser demo signs out. No production bearer token
is persisted in browser local storage. Secure native session restoration remains
the standard configuration for a deployed HTTPS API.

Passwords and document contents are not stored in client files or logs. Account
email can be explicitly remembered in memory while the app stays open; passwords
are never remembered. Unchecking that option removes the remembered address.
Account
data is typed and own-scoped; changing authentication discards the form navigation
stack. Expired/revoked/restricted sessions cannot open authenticated home.

## Contract and implementation

Reviewed backend base: `4e3a66d843e368f158c0f888500c439147751ca7`. The account adapter
and shared registration service are in backend commit `d2c2f7b`; its executable
contract is `docs/RIDER_ACCOUNT_API.md`. This is accepted local source/test
evidence, not proof that production has deployed these endpoints.

Implemented calls are token login, current-token logout, own `/rider/me`,
registration options, email send/verify and multipart `/rider/applications`.
All other routes in [the larger API proposal](api/CONTRACT.md) remain proposed.
Approval, account activity and adult eligibility are read from shared server
policies; an approved account flag does not grant placement or parcel authority.

`lib/features/auth/data/` owns DTO/transport/repository behavior;
`auth_controller.dart` owns session state; views render forms and own-account home.
The existing Bagoo mark, licensed Plus Jakarta Sans and Rider visual tokens remain.

## Verification and limits

Flutter checks cover login/home/logout, typed responses, expiry, failed logout,
redirect/header safety, OTP/document submission, draft retention and responsive
layouts at 320–1440 widths and 200% text. Run `flutter analyze` and `flutter test`.
Linux and debug web builds are checked with the local configuration above.

Backend checks exercise actual account credentials, restricted/wrong-role inputs,
token scope/expiry/revocation/password changes, verification failure and private
uploads, plus existing web registration regression cases. Live local HTTP checks
verify both web-created account native login and native-created account web login,
with real SMTP delivery to the synthetic inbox. Native Flutter browser account
interaction is checked separately from backend web UI.

The clean backend baseline has 47 existing full-suite failures; comparison found
the same identities/types/causes after this adapter, with no new failures. These
remain backend roadmap gates. These local checks alone do not certify Android
or production deployment. The subsequent [Azure acceptance record](AZURE_ACCOUNT_ACCESS.md)
records actual HTTPS, email and physical Android checks with their remaining limits.
