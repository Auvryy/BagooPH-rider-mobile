# HDB-01 implementation and verification

October 13, 2026. Branch: `fix/home-read-recovery`, based on the local planning
commit `d581e4e` above mobile `main` `e04a253`. The user activated HDB-01 and
additionally requested a fix for unwanted Settings text/page movement and a
review of the resulting UI. Publication and PR merge remain user-owned.

## Result

Home, queue, selected-detail and append failures now have separate read scopes.
Only an accepted read for the affected scope clears its failure. Successful Home
data does not dismiss an uncertain command, its saved UUID or retry restrictions.
Command reconciliation can fail while the accepted dashboard remains available;
a confirmed committed result clears the corresponding command failure.

Direct-open and refresh-time selected-detail 404s use the same invalidation path.
The row, pin and selected stop disappear, cached availability becomes stale and
old Home/queue/detail/append responses cannot restore it. An independent binding
between the account-scoped workspace and navigation providers stops the route
synchronously, including a start or route calculation in progress. It does not
depend on a mounted/ready map, Home visibility or its next authorization timer.
Accepted destination/assignment changes and explicit loss of Home capability
also stop navigation. Account denial clears private work before asynchronous
session cleanup finishes. A transient detail failure retains a labelled stale
selection and requires refresh.

Queue metadata comes from the accepted request rather than a shared last-page
field. Failed appends retain the loaded rows and page, offer an explicit retry
and keep their error until the affected read succeeds. Search states that it
covers loaded tasks. Refresh/load-more controls respect in-flight work, stale
data and server cooldowns; cooldown expiry refreshes their enabled state.

Settings no longer accepts page dragging merely because bounce physics were
forced onto content that fits. Read-only information wraps in place, remains
selectable/copyable and has no separate internal scrolling. Long pages, forms,
keyboard access and large text retain their ordinary scrolling.

Visual review also exposed fragmented bottom-navigation labels at 200% text.
The ordinary four labelled destinations remain; when their captions cannot fit,
four labelled icon controls keep their tooltips/semantics and a full-width
selected caption uses the requested text size. The narrow desktop rail widens
for its labels and can scroll in short windows. Existing neutral surfaces,
accent, touch feedback, safe areas and Home's normal scrolling are preserved.

## Source and boundaries

Backend `main` was read only at `b91f13a57c7fedbd0252b0d98eeefe834b160aee`.
Reviewed courier flow, roadmap, native operations controller/task service,
operations/settings contracts and relevant test source. The accepted operations
OpenAPI remains version `1.0.0`, 25 methods/24 paths, SHA-256
`8b09acf2e933441ee766820c94f65eafe1240c6c343b659e89487c6ab1e507eb`.
Source authorization semantics remain 401 session loss, 403 account/ability
denial and 404 hidden/unknown task.

At final review, the website owner had advanced to `f96adb3` on
`feat/handover-issue-reporting`, with unrelated handover implementation and
courier-layout changes in progress. The selected native operations controller,
task/command services and contract still have no diff from `b91f13a`; the new
trim exclusion applies to website handover routes. All of that external work was
preserved and no checkout, staging, reset, test/database or deployment action was
performed there.

No backend code, branch, data, contract or deployment changes were made by this
mobile branch. No new
API or credential is required for these client fixes. Azure remains the ordinary
account endpoint, the private Geoapify configuration is retained and operational
writes remain disabled. HDB-02 onward, account compatibility changes, scanning,
outcomes, Trips, Messages and cash integration retain their separate scope.

## Verification

The initial two maintained controller regressions failed against the previous
implementation: a recovered Home error remained visible and a refresh-time 404
did not mark/remove its task. The resulting checks cover read/command separation,
uncertain UUID preservation and reconciliation, first-page/append failure and
recovery, transient stale detail, late responses, accepted access denial before
slow cleanup, destination changes, and cancellation of pending starts/routes.

Dashboard tests check pin removal, hidden Home, mapless constrained views,
cooldown controls, normal page scrolling, enlarged text, search and queue choice.
Provider integration tests use the actual persistent binding without any Home
widget and cover task loss, Home capability loss and logout. Settings gesture
tests check fitted content while the pointer is down, stationary read-only
values, Android-style copy selection, long-content scrolling and readable
navigation. Existing account/Settings/transport/navigation regressions remain
required.

- `flutter analyze --no-pub`: no issues.
- `flutter test --no-pub --reporter expanded`: **161 passed**, one expected
  explicit-configuration skip, on the final runtime source.
- Ordinary Linux release build and ARM64 Android debug APK both pass using the
  existing ignored map configuration. The default deployed HTTPS account
  endpoint/native storage and disabled work-write gate were verified without
  printing configuration values.
- Synthetic render review uses the existing font/icon-loaded widget captures
  under ignored `build/settings-ui`; it contains no live account/task data.
  Normal phone Settings, 320-width/200% text and a short 840-width/200% text
  navigation rail were inspected. The message keyboard/composer regression also
  passes after the final navigation correction.
- No phone was detected by the Android SDK device check. Physical touch, GPS,
  notification and screen-off acceptance remain open. No fresh Azure login,
  operational write or real provider request was made during this branch.

These checks certify the selected local fixes, not every HDB/backlog card or the
complete delivery workflow. See [acceptance](ACCEPTANCE.md) for the separate
Azure and physical Android requirements.
