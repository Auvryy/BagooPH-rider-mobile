# Rider Home, Trips, Messages and Settings

This Flutter slice follows the courier website at reviewed backend main
`fe86abf` and the mobile page blueprints P05, P18–P22, P25 and P29–P36.
The user confirmed this is the Rider app. Website source was read only.

## In the authenticated app

Approved Rider accounts open a shared workspace with **Tasks, Trips, Messages,
Profile** navigation. Tasks is Home. Settings opens under Profile with a Back
path. Phones use bottom navigation; wider windows use a navigation rail.

Home uses the actual account name and approval. Profile shows only own-account
fields returned by the accepted `/rider/me` contract. Assignment and vehicle
details are unavailable in that resource; missing fields do not imply an
unassigned rider. Pending/rejected accounts keep their existing holding page
and feedback. Losing approval or signing out closes private overlays and drops
workspace state.

The current native backend exposes account APIs only. Production queues, trips
and conversations therefore show **unavailable** states with a configured
first-party website link. No fixture data or zero totals are presented as live
records. No proposed operational URL is called. See the
[backend handoff](api/WORKSPACE_HANDOFF.md) for the remaining native contracts.

Settings provides real account refresh/sign-out, privacy/security guidance,
help, actual package version and open-source licenses. Supported web account
management opens in the system browser. The address must be a matching HTTPS
courier origin, and browser URLs never include the native token or credentials.
An unsuccessful browser launch shows feedback. Unsupported native contact,
password, closure, theme, language and notification mutations are not invented.

## Review all page interactions without an account

```sh
flutter run -d linux --dart-define-from-file=config/workspace-preview.json
```

Choose **Preview Rider pages**. For a connected Android phone, select its Flutter
device instead of `linux`. Chrome also supports this layout-only profile.

The full preview is gated by both debug mode and `WORKSPACE_PREVIEW=true`.
Release/profile builds exclude its entry and route even if the flag is supplied.
The profile does not configure a backend, and preview navigation never signs
in, changes the auth provider or persists a token.

- Home: switch three separate sample queue scenarios, search parcels and open
  read-only parcel details. Claim, scan, custody and delivery operations are not
  performed.
- Trips: search the returned sample history, filter payment/date, move through
  ten-record pages, inspect recorded checkpoints and copy a parcel reference.
  The scope is sample final-mile history. Delivery does not mean buyer receipt,
  remittance or earnings.
- Messages: search parcel-linked participants, switch compact list/thread or
  wide two-pane views, retain separate drafts and inspect a read-only assignment.
  Preview send adds a local bubble labelled **Preview · not sent**. It delivers
  nothing. Read acknowledgement is limited to the active, visible conversation.
- Profile/Settings: inspect sample identity, nested security/help/about views
  and Exit preview. No real account or server preference is changed.

The older `HOME_PREVIEW` demo remains available separately; its behavior is
recorded in [HOME_PREVIEW.md](HOME_PREVIEW.md).

The later [account-settings preparation](SETTINGS.md) adds contact/password/
additional-email forms to this preview and a server-version-gated adapter.
Actual native settings commands still await the owning backend API. The supported
website management action now opens `/account/settings`.

## State and verification

Page controllers/repositories separate presentation from data access. Workspace
instances are scoped by account and preview identity. Late obsolete queue
responses cannot replace the selected queue; disposal ignores late responses.
Conversation drafts are phase-bound and invalidated when a thread disappears
or becomes read only. Failed refresh/send/read responses do not become success
or clear a draft/unread count. Private state is memory-only.

Use `flutter analyze` and `flutter test`. The page checks cover authenticated
unavailability, preview isolation, navigation, trip filters/pagination/detail,
message drafts/read-only behavior, browser allowlisting/failure, approval loss,
sign-out confirmation and 320–1440 widths including 200% text and a simulated
keyboard. These checks do not certify a physical Android keyboard or live
operational API integration. The user deferred phone checks to a later session.

Recorded checks on October 8: static analysis and all 55 local tests passed;
the Android release and Linux debug builds passed. The release APK was built
with the workspace preview flag deliberately enabled: sample parcel/trip/
message identifiers and `/workspace-preview` were absent from its native
library, while the Azure API origin remained present. Internet permission,
backup disabled and cleartext disabled were verified in the packaged manifest.
Release signing/application identity remain the existing development scaffold.

The actual native Linux preview completed navigation and rendered review at
430 × 900 logical pixels. Captures under ignored build output show Home, Trips,
Messages, conversation and Settings. Initial screenshot-boundary/scroll test
failures were corrected before that passing run. This is native desktop layout
evidence, with no real account, Android-device or operational API claim.

Message read requests carry the rendered phase/message boundary. An older
render cannot acknowledge a newly arrived message; a completed read does not
clear newer unread data. Offstage and paused-app checks verify that read requests
resume only when the selected conversation is visible in the foreground.
