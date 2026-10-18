The selected [Home dashboard/navigation extension](plans/home-dashboard-navigation/README.md) now owns the local live Home adapter, map-first dashboard and explicit route navigation. Its [acceptance record](plans/home-dashboard-navigation/EVIDENCE.md) distinguishes local checks from provider, Azure and physical Android requirements. Historical fixtures below remain isolated tests.

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

Operations v1 now supplies live Home/queues, retained Trips and assignment-bound
Messages when a fresh native session and Home capabilities allow them. The
[parcel/Trips slice](plans/rider-orders-delivery-trips/README.md) is merged; the
[Messages slice](plans/rider-assignment-messages/README.md) connects paged threads,
history and original send/read intents. Their Azure and physical acceptance stay
separate, and their new writes retain independent default-false acceptance gates.
Missing or denied resources show truthful unavailable states and the configured
first-party website fallback. Fixtures never provide ordinary app success.

Settings provides real account refresh/sign-out, privacy/security guidance,
help, actual package version and open-source licenses. Native contact/password/email management opens in Flutter. Reviewed identity
correction and forgotten-password recovery open their specific website workflows. The address must be a matching HTTPS
courier origin, and browser URLs never include the native token or credentials.
An unsuccessful browser launch shows feedback. Unsupported native contact,
password, closure, theme, language and notification mutations are not invented.

## Isolated automated layout checks

The standalone sample workspace was retired from the app. Ordinary builds use
Azure and require real account access; there is no Preview Rider pages button
or route. Historical WORKSPACE_PREVIEW flags do not change this behavior.

Widget tests mount sample repositories directly in a test harness. They never
sign in a real user or persist a real token. The following interactions describe
fixture coverage, not an app mode available for phone installation:

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

The historical Home fixture also runs only in widget tests; see
[HOME_PREVIEW.md](HOME_PREVIEW.md).

The later [account-settings preparation](SETTINGS.md) adds contact/password/
additional-email forms to the test fixtures and a server-version-gated adapter.
Native Settings uses the deployed version 1 contract. Generic website management
buttons are removed; private password/email acceptance remains outstanding.

## State and verification

Page controllers/repositories separate presentation from data access. Workspace
instances are scoped by account and preview identity. Late obsolete queue
responses cannot replace the selected queue; disposal ignores late responses.
Conversation drafts stay in memory under the exact assignment/participant thread;
a partial page's absence does not prove access loss. Fresh selected denial,
read-only permission, account loss and disposal clear inappropriate drafts.
Uncertain original send/read bodies and UUIDs use a separate account/API-scoped
secure journal across restart. Failed responses do not become optimistic success.
Only a selected foreground message rendered in the viewport can set a read
boundary; confirmed reads cannot regress when an older history page arrives.
Hidden/background/access changes cancel private list/history reads.

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
