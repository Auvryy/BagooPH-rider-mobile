# Rider workflow updates

This owner-selected branch brings existing rider features into line with the
current website. It starts from mobile main `5d68493` and reviews web main
`f001d39`. It changes the rider client only; server authorization, approved
accounts, original custody, prices, evidence and financial journals remain owned
by the backend.

## Selected work

- Registration: current sex choices, readable server-versioned Terms/Privacy,
  explicit consent, field errors and recoverable requirement loading.
- Trips and Cash: accept the current original earnings ledger without treating
  collected COD as income; preserve unavailable historical values and show the
  server's shift/remittance information.
- Home: prioritize current parcels and the next permitted action, retain saved
  stop locations, and clearly separate sample maps from operational information.
- Assignment: consume the existing company directory, requests and exact offer
  acceptance with original-command recovery and fresh server permission checks.
- Verification: exercise native contracts and responsive layouts, check ordinary
  builds, and record deployment/phone limits independently from fixture success.

The current [task map](../../TASK_TRACKING.md),
[backlog](../../SUBTASK_BACKLOG.md) and [source rules](../../SOURCES.md) remain
authoritative. These changes extend the implemented account, Home, parcel,
Trips, messages and financial foundations; they do not declare all their major
areas complete. The backend's selected version-two routing, evidenced automatic
completion and retained earnings rules take precedence over older mobile prose
that assumes every order needs a later buyer confirmation.

## Boundaries and acceptance

Registration must send current versions, never bundled policy acceptance. Valid
zero earnings must load; malformed amounts and unverified money sources must
fail. Shift information explains the backend decision and cannot close custody
or acknowledge someone else's cash receipt. Company acceptance must preserve
exact displayed terms, its original request key and explicit consent.

Existing independent write gates must not be enabled merely because unit tests
pass. Unsupported or unverified operations stay unavailable with a useful next
step. No bank gateway, paid routing service, live GPS claim, new delivery
shortcut, buyer completion button, push provider or simulated production success
is added. Physical Android camera, permission and lifecycle acceptance remains
distinct from Linux layouts and isolated native API checks.

Status: selected client batch complete and locally verified. Deployed company
and physical-device acceptance remain open. Planned effort was
16 client hours within October 29–31, 2026; measured time and any external wait
remain separate.

## Registration verification

Current policy-contract tests and registration/account widget checks passed,
including explicit sex/consent submission, an unchecked-consent rejection before
email verification, policy-link boundaries and phone/tablet text reflow. Policy
versions are loaded rather than copied into application configuration. Actual
new-account registration on a physical device is a separate acceptance step.

## Earnings and shift verification

The current original-earnings shape now loads in Cash and retained Trips,
including zero balances and amounts above JavaScript integer precision. Released
and pending earnings are displayed separately from collected/remitted/held COD.
Home and Cash retain the server shift summary and explain pending hub receipts
and differences without acknowledging cash or changing closure authority.

All 46 focused contract, repository, controller and Cash/Trips page cases passed.
Three additional financial summary widget checks passed at 320px with normal
and doubled text, including the cash-review action and unavailable-value
behavior. Fixtures now use the current ledger shape; historical unavailable
earnings still have explicit coverage. These are overlapping focused selections,
not full-suite or physical-cash acceptance.

## Company joining

Profile → Assignment now opens the native company directory and the rider's
saved requests when the current server advertises company API version one.
Applying requires an explicit work-profile sharing review. Accepting requires
the exact saved hub, vehicle, barangay and arrangement terms, with fresh
request/offer versions. Declining and withdrawing retain the request history.
Accepting does not switch duty on. Unavailable sessions retain the existing
website fallback.

Uncertain commands keep their own protected account/API-scoped journal, separate
from parcel, cash, message and notification commands. Recovery checks the
original UUID before an explicit unchanged retry. Backgrounding and account
changes clear private views; stale offers cannot dispatch. Offer and assignment
notifications recheck current account access and open these native details.

The 68 selected company/notification contract, repository, controller and widget
cases passed, followed by the additional account-change entry guard. The
windowless native-Dart/real-Laravel check against frozen backend
`f001d39` passed submission, stale-offer denial, original-command recovery and
exact acceptance, with one consent/placement and duty off. Its database was
SQLite `:memory:` and its secure-storage adapter was explicitly mocked. See the
[runner](../../../tool/company_local_api/README.md) for reproducible boundaries.

## Home and current stops

Home presents task queues before the optional illustration. Selecting an owned
parcel shows its saved stop beneath the task details. Missing or invalid pins
keep an address-based next step. The sample map starts collapsed and remains
explicitly labelled when opened. Home/Cash continue to use the server's shift
and custody decisions.

Both the bundled Leaflet renderer and Linux Flutter map display one saved-stop
pin without a sample road or an invented rider location. Recentring, touch/drag
controls, tile failure recovery and attribution are retained. Stop labels are
encoded as data and rendered as literal text. Parcel changes close the old
renderer and ignore its late callbacks; hidden Home releases the map.

Focused Home, pin, policy and runtime checks passed, including selected stops at
320px with doubled text, portrait/landscape/tablet layouts, unsafe labels,
missing coordinates and old-renderer cleanup. The full regression includes
the older sample-map checks with the new explicit open action. This branch
does not introduce live GPS, an in-app road-routing service or offline map tiles.

## Final validation and handoff

The final unchanged-source run passed on October 29, 2026:

- `flutter analyze --no-pub`: no issues.
- `flutter test --no-pub --concurrency=1`: 682 passed, six skipped.
- `node --test tool/test_delivery_map_runtime.mjs`: four passed.
- Isolated company runner at backend `f001d39`: passed current registration,
  Home/shift and zero-earnings reads, plus original submission/acceptance recovery.
- Configured Linux debug build with Device Preview: passed.
- Configured Android debug APK: passed.
- Changed-document links and `git diff --check`: passed.

The six ordinary-suite skips are three opt-in rendering checks, an opt-in map
benchmark, an explicit-API-definition configuration case and the separate
company-kernel case. The latter passed through its dedicated runner. No visible
browser, production database, live financial write or physical device was used.

The existing ignored configuration file was preserved. Only its already-enabled
duty/claim profile remains enabled; parcel, prepaid, cash, message, notification
and handover write gates were not expanded. Ordinary builds keep real account
access rather than replacing the app with sample data.

From the rider repository, start the usual phone preview with:

```sh
flutter run -d linux --debug --dart-define=DEVICE_PREVIEW=true --dart-define-from-file=.env.rider.json
```

Check Profile → Assignment for company requests, Cash/Trips for financial reads,
and an owned Home task for its current stop. The Android artifact is
`build/app/outputs/flutter-apk/app-debug.apk`; the Linux bundle is
`build/linux/x64/debug/bundle/bagoo_rider_mobile`.

Local feature commits: `52c551b` (registration), `36e17f5` (earnings/shift),
`bfe4d73` (policy validation), `d6a8ae8` (company requests) and `3c2b586`
(Home/stops). The [pull request description](PULL_REQUEST.md) is a separate local
draft; nothing was pushed or saved on GitHub. The website/backend and buyer
mobile projects were not edited.

## Scoped assessment

These engineering estimates describe client compatibility and local usability,
not deployed or physical-device acceptance:

| Changed feature | Before | After | Evidence and remaining limit |
|---|---:|---:|---|
| Registration requirements | 55/100 | 85/100 | Current versions and consent are submitted; physical new-account capture remains separate. |
| Earnings and cash-shift reads | 45/100 | 88/100 | Current zero/nonzero ledgers load and money sources stay separate; live cash writes remain gated. |
| Company joining | 25/100 | 83/100 | Native exact-offer consent and isolated real-kernel placement pass; deployed/Android acceptance remains separate. |
| Home work and saved stops | 60/100 | 86/100 | Task-first layouts and saved pins pass locally; physical gestures and real GPS routing are not certified. |
