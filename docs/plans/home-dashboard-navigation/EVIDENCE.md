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
- Real-provider quota/cooldown acceptance beyond the successful tile/route checks
  recorded below.
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


## Live provider configuration follow-up

A dedicated Geoapify key is now supplied through ignored project-local JSON.
Both direct HTTPS smoke requests returned 200: the map endpoint returned a valid
PNG and motorcycle routing returned GeoJSON MultiLineString road geometry.
An additional real-network Flutter smoke check passed using the actual
GeoapifyClient and RoadRoute parser: one PNG tile and a route between two public
sample points. It sent no Bagoo bearer or rider location. The smoke-test source
and build inputs remain ignored; no actual key enters tracked files or logs.

Current backend reference `a1eb08b20bab8afb2a109f8c8e84ea0bba5dd600` was read only.
The selected task/command controllers/services and accepted OpenAPI are unchanged
from `1d785aa`; the contract fingerprint remains
`8b09acf2e933441ee766820c94f65eafe1240c6c343b659e89487c6ab1e507eb`.
This source comparison does not establish Azure deployment or authorized reads.
A backend verification handoff was prepared separately from tracked documentation.

The debug APK rebuilt successfully with the private provider configuration and
writes still disabled. The real-network smoke test and native build logs were
checked for accidental key disclosure; no key appeared in either log. Provider checks do not establish authorized task selection,
physical Android GPS/background behavior or real quota-exhaustion handling.


## Home refinement after reported Azure rollout

The [Home refinement](HOME_POLISH.md) implements compact counted queues,
responsibility-first presentation, selected stop/map focus, responsive panels,
search preservation and immediate removal of hidden/freshly unlocated pins.
A read-only live check using Flutter's actual authenticated transport and operations
adapter passed: fresh approved login discovered version 1; Home and the three
queues returned valid resources with zero tasks. Its verification token was logged
out. No live duty, claim, custody or cash mutation occurred.

A separate earlier generic HTTP probe's logout was blocked/unconfirmed. Bearers
stayed in memory and were not printed; no global token-count cleanup audit is
claimed. Backend-source review is `5068c66`; exact VM/migration evidence and
positive live owned task detail remain separate prerequisites for write activation.

Final analysis is clean. The full Flutter suite passes 136 tests with one expected
explicit-configuration skip. Meaningful Home/queue tests and the account/Settings/
workspace regressions cover the resulting behavior, including lost approval closing
an open private sheet. Four before/after synthetic render checks pass at 390 and
1440 widths using the bundled/system fonts, Material icons and cached public tiles.
The reviewed outputs preserve visible attribution and contain no key or live
personal task data. Ordinary Linux and Android debug builds pass with the ignored
Geoapify configuration. Diff, Markdown links/fences, key-in-source/log and private
file checks pass. No physical Android navigation acceptance is claimed.

## Android phone installation — October 10, 2026

The current source rebuilt as an ARM64 debug APK with the ignored Geoapify
configuration and the Azure account/API origin. Operational writes remain
disabled. It installed successfully over the existing app on the connected
Android 16 (API 36) phone, preserving its data, and launched successfully.
The application remained running in the foreground; its startup log contained
no fatal Android exception or unhandled Flutter runtime error.

This establishes installation and startup on the phone. Sign-in, authenticated
Home/queue reads on that phone, owned-stop routing, permissions and background
GPS behavior still require device testing; no physical navigation acceptance
or live operational mutation is claimed by this check.
