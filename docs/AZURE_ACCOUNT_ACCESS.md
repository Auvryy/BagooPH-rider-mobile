# Deployed HTTPS account access

The account contract was reviewed against backend main `0132562`. The web
maintainer reported this revision deployed to the Azure VM; external HTTPS
checks confirm that its account routes are available. Source review and public
HTTP checks do not independently establish the VM's Git checkout hash.

The public build profile is [config/azure.json](../config/azure.json). It contains
the API origin and preview switches, with no credentials or signing material.
The Rider website uses `https://courier.bagooph.shop`; the root website host
is reserved for buyer login by its web middleware. Native API calls continue
using the root host's `/api/v1` contract.

```sh
flutter run -d linux --dart-define-from-file=config/azure.json
```

For an authorized Android phone, select its device in Flutter and use the same
profile. Native sessions use platform secure storage. Android has Internet
permission, disables application backup and requires encrypted network traffic
in release/profile. Debug builds permit local HTTP only when the existing
loopback-only app configuration is explicitly selected.

The Chrome Home demo remains an isolated layout preview. Azure account access
uses the native app; browser account sessions and deployment CORS changes remain
separate work.

## Sessions and approval

Secure-storage keys include the configured API identity. A staging session is
never restored or sent to a different configured API. Legacy tokens saved
without an API identity are discarded rather than migrated across environments;
an older native installation signs in again once after this change.

The app validates courier/account/review/access fields and renders the actual
server feedback. Returning to the foreground refreshes a signed-in account.
Server 401/403 responses remove ordinary account access; a failed network logout
retains the session for retry. Tokens are never stored in browser local storage,
client documents or logs. The server owns expiry, approval and restrictions.

## Verification recorded October 7, 2026

| Check | Evidence so far |
|---|---|
| Public registration options | Azure HTTPS 200 JSON, verification required, 5 MB documents and expected vehicle choices |
| Anonymous own-account/logout | Azure HTTPS 401 JSON, private no-store headers |
| Existing website Rider account | Live HTTPS website login returned the Rider deliveries page with the expected account identity; native Linux and physical Android Flutter login passed |
| Secure device storage and restoration | Actual Linux keyring write, new-repository restoration and environment isolation passed |
| Logout and revoked token | Native Linux logout cleared storage; the server rejected the old token with 401 |
| Pending/rejected feedback, restricted and expired responses | Local consumer/widget checks passed; live native signup confirmed pending review. Live rejected/restricted transitions and expiry boundaries have not been claimed |
| Real email verification and documents | Native Linux registration reached verified pending home after a privately entered delivered code and three actual multipart synthetic document uploads |
| Website sharing | The initial signup check targeted buyer-only web login and failed. The corrected helper targets the Rider subdomain. Existing-account credentials work, but its HTTPS redirect check fails; the new account's website login remains pending |
| Physical Android | Actual phone login, encrypted storage, new-repository restoration, environment isolation, logout and revoked-token denial passed |
| Release packaging | Azure-profile APK compiled; packaged manifest has Internet permission, backup disabled and cleartext disabled. Demo routes/data and public test credentials are absent from the native release library |
| Latest extended Linux check | Native wrong-role denial, login, secure restoration, isolation, logout and revoked-token denial passed. All website account fields matched over fixed HTTPS requests and website logout succeeded. The aggregate test failed because the server's sign-in redirect used HTTP |

Static analysis is clean and all 34 local Flutter tests pass. Rejected feedback,
expiry and newly restricted account transitions use controlled local responses;
these results do not claim a live account was suspended, rejected or aged past
its token lifetime.

The first Android attempt exposed a debug/main cleartext manifest conflict,
which was corrected with the debug manifest override. The first device install
was denied by the phone; a subsequent installation succeeded. Both are recorded
as initial failures, not passing attempts. A normal main-entry app was installed
and launched after the automated check, so the user can interact with its login.
The user also reported login working. They deferred the new account's website
check and later disconnected the phone; no further physical-device result is
inferred from Linux tests or the release build.

The signup check completed email verification, three private multipart uploads
and pending home before failing its website-login assertion. It is a partial
live result, not an all-passing signup test. The test account remains pending
review with synthetic documents; it has not been approved. Its generated test
password was not saved. The user can set a password privately through the
website's Forgot password page, then check the same account on the Rider website
and phone without repeating registration.

Only fields supported by the accepted account contract are displayed. Parcel
operations, placement/profile expansion and operational task endpoints remain
separate backend prerequisites.

## Build a device APK

```sh
flutter build apk --release --dart-define-from-file=config/azure.json
```

The package is `build/app/outputs/flutter-apk/app-release.apk`. The current
Android scaffold signs release builds with the development debug key and uses
the scaffold application identifier. This is a test build, not a store release.
The compiled release APK has not been installed or exercised on the phone.

## Repeat controlled native checks

```sh
flutter test integration_test/azure_account_test.dart -d linux --dart-define-from-file=config/azure.json --dart-define=LIVE_AZURE_CHECK=true
```

The check uses the backend's public website seed credentials and actual platform
secure storage. It refuses to replace an existing native session and revokes its
temporary token. Its extended check also denies a buyer login and compares native
account details with a separately authenticated Rider website session, then logs
out that website session. Use the Android device instead of `linux` to repeat on
a phone. The earlier Android run covered account login/storage/logout; the added
website comparison and wrong-role checks require their own recorded run.
The extended Linux run is recorded above. Its full acceptance result currently
fails at the website HTTPS-redirect assertion; the preceding native checks pass.

## Website deployment issue

An actual HTTPS POST to the Rider website's login accepts the existing Rider
credentials, then returns a same-host HTTP deliveries URL. The native API's
HTTPS JSON requests do not have this redirect problem. The website helper reads
only the fixed HTTPS account page and does not follow the downgrade. Its full
acceptance check requires both matching account fields and an HTTPS redirect.

The web maintainer should verify the Azure production environment, HTTPS app
URL, secure session-cookie setting and proxy scheme/configuration cache. Their
newer backend source contains web-session/origin changes at `6e59b53`; the
account API resource remained unchanged from the accepted `0132562` contract
on the follow-up source read. This source review does not establish deployment
of those newer changes. No backend file or VM configuration was changed here.

## Controlled registration check

The live registration check is separately opted in. It reads a private email
input under ignored build output, creates a clearly named test application with
three labelled synthetic PDF uploads, and generates its password in memory.
The user enters the delivered code privately in the native verification dialog;
neither code nor password is printed or committed. File selection is a test
adapter, while multipart upload and the backend account are real. This check
does not certify a physical camera or native picker interaction.
