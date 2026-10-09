# Dashboard/navigation implementation evidence

## Live-data phase

Implemented accepted v1 Home/queues/detail decoding, account discovery, transport
command headers and safe error codes/request IDs. Duty/claim writes persist their
original UUID intent before dispatch; timeout/restart retains it and reconciles.
Reads require discovered version 1 and current approved identity. Production
writes additionally require an accepted-deployment build configuration.

Seven operations contract tests and eight existing workspace controller tests pass.
They check exact IDs/cents, coordinates/privacy, pagination, persist-before-send,
timeout/restart/replay, unknown/expired commands, missing storage, deployment and
account gates, claim body and fresh owned detail. Full existing/local Flutter suite: 107 tests pass with one expected explicit-configuration skip. Analysis is clean. Native builds and later-phase checks will be recorded after implementation.

## External acceptance outstanding

- Actual Azure deployed revision and migration status, including rider_commands.
- Fresh approved rider bearer/version/Home/queues/detail and denied access checks.
- Authorized duty/claim reflected in the owning website, stale/competing claim
  and uncertain-response recovery through the native client.
- Dedicated Geoapify client key and real-provider route/quota checks.
- Physical Android precise/notification denial, screen-off/minimized updates,
  stop/resume, permission removal, reassignment and authorization revocation.

No Azure operational mutation or physical navigation acceptance is claimed.

## Map, route and navigation phases

Implemented flutter_map Home with an expandable three-queue panel, valid stop
pins, common card/pin selection, compact duty/eligibility/counts, fresh owned
navigation detail, external directions and attribution outside the panel.
Small keyboard-constrained views retain scrollable tasks. Settings/account
regressions and enlarged-text layouts pass.

Geoapify tiles and road routes share a separate client and a four-request/second
scheduler. Tiles cache in memory; missing key, quota/cooldown, malformed geometry
and route failures remain explicit. GeoJSON preserves separate lines and correct
longitude/latitude order. The controller validates fixes, trims the road locally,
requires two good off-route fixes above 75 metres and limits calculations to once
per 30 seconds. Queued calculations cancel when their origin fix expires.
Panning disables follow until Recenter. Cancelled/late results cannot replace a
new selection. Manual Linux routing uses an explicit origin/profile.

Android uses geolocator's foreground service, precise foreground/notification
permission requests, an ongoing notification and wake lock. A persistent
account-scoped controller stops streams/timers/requests on Stop, logout, permission
removal, denied/reassigned/changed tasks and disposal. Per-minute authorization
and an independent two-minute expiry preserve the revalidation boundary even
when a request hangs. Location and outcome authority remain separate.

Local automated evidence: full Flutter suite passed **128 tests**, with one
expected explicit-configuration skip. After the final cancellation review,
**12 navigation tests** passed, including queued-origin expiry and late account
responses. Analysis is clean. Transport tests cover allowed command headers,
origin/bearer isolation, stale/denied/unavailable/quota errors; the shared native
transport also enforces rolling 30-request/10-write budgets. Three dashboard
widget checks cover card/pin/detail selection and 320/1440-width enlarged text.
Provider/controller mocks are test-only and do not establish real road/GPS behavior.

Ordinary `flutter build linux` and `flutter build apk --debug` pass on the final source. The debug APK is generated without a provider key or operational-write activation. A plugin deprecation notice is not a build failure. No Android phone was connected. Plan links/fences, fixture JSON, scope/privacy and Git whitespace checks pass. Local commits are reported with the handoff; no push was performed.
The backend worktree was read only. No deployment, real-provider request, live
operational mutation, physical Android test or travelled-location upload occurred.
