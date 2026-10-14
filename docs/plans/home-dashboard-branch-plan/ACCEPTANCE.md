# Home acceptance matrix

This checklist applies to the selected branch's scope. Rows remain open until
the required evidence exists. Do not interpret a local unit test, a mock location,
a Linux phone frame or an APK build as a physical Android or Azure acceptance.

## Local review and regressions

- [x] HDB-04 verifies fresh owned Stop Mode, preview privacy, exact identifiers/COD,
  copy/contact/directions guards, changed stops, denied/late/cooldown states and
  resume/Back/keyboard behavior. Selected layouts cover 320/390/840/1440 widths
  at normal/200% text. Covering Home suspends its map while navigation continues;
  a known handover hold prevents or stops navigation.
  [Scoped evidence](HDB-04-EVIDENCE.md) keeps actual collection/departure,
  Azure and physical Android acceptance separate.
- [x] HDB-03 verifies returned placement/counts/capacity, observed freshness,
  shared friendly stages, failed-first-read recovery and reachable overview
  controls across the six selected widths at normal/200% text with keyboard.
  [Scoped evidence](HDB-03-EVIDENCE.md) distinguishes local UI checks, existing
  API source, ongoing handover work and still-open Azure/physical acceptance.
- [x] Inspect baseline Home entry/shell, queues/search/paging, selected detail,
  duty/recovery, map/attribution and navigation controls.
- [x] Run the existing five related suites: 43 tests passed on October 13.
- [x] Reproduce BUG-H01–H05 with five isolated diagnostic probes against baseline.
- [x] HDB-01 maintained regressions expect recovered read errors to clear and
  refresh-time hidden tasks to lose their row/pin/active route immediately.
  [Final evidence](HDB-01-EVIDENCE.md) includes hidden/mapless views, pending
  start/route cancellation, unresolved commands, source review, 161 tests,
  analysis and ordinary builds. It does not close the broader rows below.
- [x] HDB-02 maintained regression expects normal location-stream completion to
  stop navigation once; old stream callbacks cannot restart or modify it.
- [x] HDB-02 maps the registered Sedan / Van alias while preserving explicit
  unknown-vehicle choices and registered-profile precedence.
  [HDB-02 evidence](HDB-02-EVIDENCE.md) records 179 tests, analysis/builds and two
  public provider samples; broader runtime/physical rows remain separate.
- [ ] Confirm 320/390/430/840/1000/1440 logical widths, 200% text, long identifiers
  and addresses, reduced motion/high contrast, keyboard and window resize.
- [ ] Verify one normal phone page scroll, bounded map/notices/attribution and
  bottom navigation clear of all final controls. Do not restore drag handling.
- [ ] Cover loading, refreshing, truly empty, no matching loaded rows, unavailable,
  stale retained data, failed refresh/append, denied access and cooldown separately.
- [ ] Cover late queue/detail/profile/route results, explicit queue choice, pin/card
  selection, selected-outside-filter state, changed/missing coordinates and a
  current stop removed after a fresh list read.
- [ ] Check Home hidden/foreground/back, active navigation banner/Stop, map camera
  follow/Recenter and bounded view-driven provider work.
- [ ] Show paused-navigation reason/revalidation with the map hidden or another
  tab active; no automatic tracking restart follows that explanation.
- [ ] Check registered vehicle precedence, explicit unknown-profile choice,
  manual-origin validation, GeoJSON order, bad/stale fixes, cancelled/failed route
  and provider quota recovery without a straight-line substitute.
- [ ] Before each runtime branch commits, run analysis and relevant meaningful
  tests. Full Flutter regression/native builds are required when shared runtime,
  dependency/platform or integration risk warrants them; do not repeat unrelated
  already-passed checks without a new concern.

## API and cross-role acceptance

- [ ] Record actual deployed revision/migrations and fresh operational abilities,
  Home flags/limits, authorized queues and a positive owned detail result.
- [ ] Verify account/Settings regression and denied/old/wrong/restricted sessions.
- [ ] Use expressly authorized isolated test actor/parcel/cash resources through
  normal seller/hub/rider/buyer workflows; record safe request IDs, no secrets.
- [ ] Duty changes desired state once, off duty retains existing responsibilities,
  one pickup claim wins and same-key replay/reconciliation keeps one assignment.
- [ ] Actual scan collection changes seller custody, then authenticated origin-hub
  intake ends pickup responsibility; Mother-Hub transport stays hub/logistics-owned.
- [ ] Hub-assigned final-mile departure changes the current stop to the frozen buyer
  destination; old route/destination/contact cannot remain active.
- [ ] Genuine original proof/recipient/exact COD delivery records one outcome and
  collection; buyer completion and subsequent recipient cash receipt stay separate.
- [ ] One failed attempt retains return custody until destination-hub receipt;
  approved retry/RTS and restricted recovery remain with their owning workflow.
- [ ] Trips retain original assignment/outcome/evidence after reassignment;
  protected parent/child proof denies foreign, missing or changed evidence.
- [ ] Messages retain phase/assignment/participant, original draft and exact
  displayed incoming read boundary; late unseen messages remain unread.
- [ ] Notices are durable server events, owned reads acknowledge only displayed
  IDs and stale/unknown/null targets do not open unauthorized data.
- [ ] Cash summary has all-owned-journal basis; an offer waits for a separate hub
  receipt and does not itself change held/remitted or invent earnings.
- [ ] Verify first-party native JSON/private/no-store/nosniff/error/cooldown behavior,
  source/server limits, original-key conflicts/expiry and no cross-origin proof/bearer.

## Physical Android

- [ ] Install the actual selected build with private local map configuration and
  normal Azure account access; validate source/build identity before acceptance.
- [ ] Real camera scan: permission denial/cancel, unreadable/wrong/matching waybill,
  process interruption and return to refreshed authorized detail.
- [ ] Real proof selection/capture: permission/cancel/replacement, file-type/size,
  original-byte retention and private cleanup across restart/account changes.
- [ ] Start Navigate while visible, request precise foreground location and
  notification permission contextually; denial keeps dashboard browsing usable.
- [ ] Real valid fixes, inaccurate/stale fixes, rerouting thresholds/cooldowns,
  ongoing notification and minimized/screen-off continuation are observed.
- [ ] Stop, permission removal, denied/reassigned/changed destination, account
  logout and a two-minute authorization outage clear/pause navigation correctly.
- [ ] Force-stop/reboot does not auto-start tracking; navigating again requires
  a rider action. GPS proximity never records collection/delivery/arrival.
- [ ] Real touch/scroll, Back, keyboard, external directions return, 200% text,
  contrast/reduced motion, attribution and device performance are reviewed.

## Completion boundaries

HDB-16 Parcel Finder is checked only if selected: account/API/assignment-scoped
labels, shared/unset slots, cleanup and no fabricated scan/custody state.

If a row cannot be exercised, record its specific missing actor, API, deployment,
source policy or device evidence. Do not check it or mark the entire M04–M16/OPS
plan done. Final identity/signing/freeze remain their separate release tasks.
