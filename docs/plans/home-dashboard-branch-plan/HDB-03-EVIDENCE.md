# HDB-03 — Home work overview and shared task stages

Selected October 14, 2026. Branch `feat/home-dashboard-overview` starts from
clean, updated mobile `main` `d6ff936`, after the prerequisite Home repairs and
Philippines map slice were merged. Estimate: six client hours; October 14–16,
18:00 Asia/Manila. State: **locally implemented and verified; user publication
and review remain pending**.

## Source and prerequisite review

The backend checkout was read only, initially clean `main` at `5de04eb`.
Its owner advanced to `fadf2299e9a10d4f456da36508f468762c691063` on
`feat/handover-api-contract` during the review and continued uncommitted H04 work.
Reviewed Home/task service, queue/eligibility behavior, executable OpenAPI,
Home/task examples, native contract/operations/boundary test source, documentation
map, courier flow and roadmap's current handover review. No backend branch,
files, database, migrations or tests were changed or executed by this task.

The Home response still supplies company/hub IDs and nullable names, coverage,
duty, eligibility/denial, active/limit/remaining capacity, three queue counts,
observed timestamp, capabilities and limits. Task resources retain original
stage, full identifier, current stop and permitted hints. Handover holds and
physical receipts remain backend-owned. Seller/hub coordinates remain unavailable; buyer stop coordinates
retain their existing authorization boundary.

- Initial committed OpenAPI SHA-256: `8b09acf2e933441ee766820c94f65eafe1240c6c343b659e89487c6ab1e507eb`.
- Initial task service SHA-256: `01a935bec0ac31c844aad0435ca2fa5012ad7f69eb34607e5f924589ecd27234`.
- Later uncommitted OpenAPI snapshot: `b1542871140dc1e3a3b29beef877f65322cea244f4d3e14bce796429e5bab4aa`.
- Later uncommitted task service snapshot: `1deae6c0f0b2eccfcf21490a3bb457c35b4a6f7da3f822f061b4e61297c38a01`.

The H04 work in progress adds nullable `handover_api_version`, boolean
`handover_issues`/`handover_reporting` discovery and four separate handover paths.
The selected Home placement/count/capacity/time fields and Task schema are
unchanged. The existing decoder accepts those additive discovery fields;
the overview checks include them while still issuing only existing read requests.
No H04 endpoint or write is connected here. These mutable fingerprints are dated
observations, not a merged/deployed contract or H04 acceptance.

Compared the selected seven cards and their 38-card canonical dependency closure
under [the prerequisite audit](PREREQUISITES.md). Existing M01 wire/transport
agreements, M02 theme/shell/asynchronous states, M03 approved native account
access, M04 queue/detail preservation, M05 duty/eligibility and M16 private
cleanup foundations are reused. This slice contributes partial presentation
coverage to M04.03–05, M04.08–09, M05.02 and M05.06. It does not complete their
later daily activity, writes, whole-flow or physical-device gates, nor change
the canonical backlog statuses.

Source evidence supports this UI work under [API-H01](../../api/HOME_DASHBOARD_NEEDS.md#api-h01).
Existing dated Azure account/Home-read evidence remains separate. This task has
no fresh authorized Azure operational session or deployed revision/migration
confirmation; source review is not deployment acceptance. Duty/claim acceptance
remains HDB-05 and the configured write gate remains off.

## Selected implementation

- Actual company, hub and coverage, distinguishing an assigned ID with a missing
  name from no assignment. One duty control preserves its existing authorization.
- Returned pickup capacity and three counted queue choices. Unknown quantities
  remain unavailable; zero and full capacity retain their server meaning.
- Server Home observation displayed as Philippine date/time, refreshing/retained
  and failed/unavailable states, with one general Refresh work action. No always-live
  feed or locally invented checked time.
- Shared display-only stage formatter for Home rows, selected stop and detail.
  Original stage and full tracking identity are preserved; unknown codes grant
  no new transition. Selected summary now includes both stage and full identifier.
- Bounded, smaller phone map at large text, one normal phone page scroll,
  attribution outside the map and bottom navigation clear of content. Wider
  windows retain the existing map/task layout and camera rules.
- A failed first Home read explains why its queue cannot yet be checked instead
  of leaving an indefinite task spinner. Retained task reads remain distinct.

## Local verification

- [x] 320/390/430/840/1000/1440 widths at normal and 200% text with long identifiers,
  placement/address text, actual workspace navigation and keyboard.
- [x] Loading, unknown/zero counts, unavailable placement, full capacity,
  refresh failure/recovery, retained observations and explicit access denial.
- [x] Row, selected stop and detail stage/identity, unknown stage, explicit queue
  choice, off-duty responsibilities and no operational writes from display/refresh.
- [x] Relevant tests, full Flutter regression, analysis and ordinary native builds.
- [x] Scope/privacy/diff review and a coherent local feature commit with its tests
  and owning evidence. Use the branch log for its commit identity; user publication
  remains pending.

Checks performed:

- Six relevant suites: **74 tests passed**. The full Flutter suite: **246 passed,
  one expected explicit-API-configuration test skipped**. Ordinary launches retain
  Azure account access; no fixture app mode was introduced.
- The 20 overview checks passed again with the owner's additive handover
  discovery fields included, still producing no handover requests or writes.
- `flutter analyze --no-pub`: **no issues** after test-only lint cleanup.
- `flutter build linux --release --no-pub --dart-define-from-file=.env.geoapify.json`: **passed**.
- `flutter build apk --debug --no-pub --target-platform android-arm64 --dart-define-from-file=.env.geoapify.json`: **passed**.
- Documentation links/fences and whitespace checks passed. Private configuration,
  the local work guide and generated receipts remain ignored and untracked.

New coverage lives in `test/home_overview_test.dart` (20 cases). It exercises
actual workspace navigation, visible touch targets and scrolling with keyboard,
refresh retention/recovery, unknown versus zero, missing placement names versus
IDs, full capacity, unknown stages and exact identifiers. Count tests deliberately
return a different Home total from the loaded page. The checked-time test crosses
the UTC/Philippine date boundary; it never substitutes device time.

Initial checks caught the narrow duty-label overflow and failed-first-Home
task spinner; both were corrected. Existing map tests now reveal controls after
scrolling the taller overview and inspect the persistent camera when offscreen;
their navigation, retry, caching and cancellation assertions remain intact.

Widget renders were reviewed at 390 and 1440 widths, normal and 200% text,
using the bundled fallback font and Material icons. They are synthetic local UI
evidence, with unavailable map tiles/coordinates and no actual Android system-font
or provider-performance claim. The Linux phone frame is a layout preview, not GPS.
Verification logs/renders remain in ignored `build/home-overview-verification/`.
`flutter devices --machine` detected Linux and Chrome, with no Android device.

## External acceptance that stays open

- [ ] Fresh authorized Azure login/Home/queue/detail comparison with recorded
  deployed revision and migrations; no credentials in project evidence.
- [ ] Actual Android touch/scroll, keyboard and accessibility review of this build.
- [ ] Physical GPS, permission/background navigation and live duty/claim/custody
  acceptance under their separate selected branches.

The app keeps normal Azure account access and private local Geoapify configuration.
No fake app mode, new dependency, aggregate metric, earnings/ETA, guessed destination,
location history, background autostart or backend write enters HDB-03.
