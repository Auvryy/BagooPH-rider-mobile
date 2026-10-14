# HDB-04 — Focused current-stop guidance

Implemented October 14, 2026 on `feat/home-stop-mode-guidance`, from clean,
fetched mobile `main` `d13eefab360fabf704ec56c3878c5f2d8a3f981f` (PR 20).
Selected estimate: six client hours, October 14–16, due October 16 at 18:00
Asia/Manila. This is an estimate, not measured time or an API rollout claim.

## Resulting behavior

Selecting an owned task and choosing **Work this stop** opens a full-page Stop
Mode with ordinary scrolling and Back/Escape. It reads owned detail before
showing the task. It shows full tracking/order references, the friendly stage,
recorded custody, the current stop name/address, the supplied next instruction,
the next responsible actor and exact COD when returned. Assignment alone does
not establish possession. Leg guidance is conceptual, not a completed journey
or an invented second stop.

Copy tracking/order/address and Call current stop each refresh owned detail.
Changing the assignment, stage, custody, destination, phone or notes cancels the
old action and asks the rider to review the updated stop. Unavailable, stale,
denied, rate-limited or late responses cannot launch an old contact. Explicit
401/403/404 removes private detail through the existing access handling. Copy
and launch feedback stays within the normal page; no draggable sheet or fixed
action footer is added. Phone URIs allow reviewed number formatting and reject
other schemes, dial codes, queries and malformed numbers.

External directions and the existing Navigate/Stop controls use fresh detail.
Directions use valid returned coordinates or the actual returned address; they
do not start GPS. Linux retains the labelled manual preview origin. Only
Navigate starts the existing route/location controller, which remains outside
the page. Stop also remains usable while navigation is starting or paused.
Confirmed changed destinations cancel the prior route through the existing
workspace binding. A confirmed `HANDOVER_HOLD` also prevents or stops navigation.
While Stop Mode covers Home, Home suspends its map and tile work; returning
restores the map without stopping the separate navigation controller. Attribution,
routing geometry, provider scheduling and background-service rules are preserved.

Actual buyer `stop.instructions` appears as plain **Doorstep Guide** text.
Other stop instructions appear only if supplied. Missing fields have explicit
fallbacks; no landmark, hub/seller coordinate, phone or address is fabricated.
Available pickup detail remains a public preview with its existing gated claim
control and no private copy/contact/navigation actions. Confirmed claims use
owned detail. No scan, collection, departure, proof, delivery, recovery or
messaging command is activated by this branch.

App resume and return from a covering route refresh the stop. Outstanding
actions are cancelled when the page is covered, backgrounded, closed, or the
selection/account changes. The live entry closes Stop Mode when an initialized
account's ID, approval or operations discovery changes. Disposed navigation
controls are not retained after that access change. The existing account and
Settings contracts remain in place.

## Current source and prerequisites

- HDB-03 is merged in PR 20. Its selected Home/transport/account/theme evidence
  is reused; the canonical backlog is not marked complete by this presentation.
- Read the selected brief, prerequisite audit, canonical coverage cards and
  source/dependency rules. M04.07, M06.05, M07.02 and M09.01–05 contribute
  partial client coverage; broader custody, cross-role, STAGING and ANDROID
  gates remain open.
- Reviewed backend `d321011` on its owner's handover branch, then the owner's
  clean merged `main` `77fb96e72fac136816eb423e6054453b4528f37c` during this work.
  Read the courier/UI rules, native API guide, task service, relevant test source,
  OpenAPI and the roadmap's October 14 handover entry. No backend file, branch,
  database, migration or test was changed/executed here.
- Final read observed the owner's `feat/rider-company-requests` at `89c85bf`,
  with company-request and workstation work in progress. The task-service and
  operations OpenAPI fingerprints below still match; that owner work was preserved
  and is not treated as a deployed API or part of this mobile feature.
- Current task-service SHA-256:
  `1deae6c0f0b2eccfcf21490a3bb457c35b4a6f7da3f822f061b4e61297c38a01`.
  Reviewed OpenAPI SHA-256:
  `fc9da7317667a6ec0b947b7c20185b4dfe6a2d2cc7106363edab8b64972a631d`.
  The newly documented `handover_hold` and denial fields are additive to the
  existing typed consumer. No handover endpoint or write consumer is connected.
- Native coordinates remain buyer-only; seller/hub pins stay unavailable.
  The owned seller-phone mapping discrepancy in
  [API-H06](../../api/HOME_DASHBOARD_NEEDS.md#api-h06) remains an owner check.
  The missing-contact fallback supports this branch without a new endpoint.
- Reused locked Flutter/platform dependencies. Checked primary
  [url_launcher guidance](https://pub.dev/packages/url_launcher) for direct
  external launch/failure handling and
  [Clipboard.setData](https://api.flutter.dev/flutter/services/Clipboard/setData.html)
  for actual clipboard completion. No package or Android permission was added.

## Verification

Final checks on October 14, 2026, after the covered-map regression fix:

| Check | Result |
|---|---|
| `flutter analyze --no-pub` | No issues |
| `flutter test --no-pub --reporter expanded` | 281 passed; one expected explicit-configuration skip |
| `flutter build linux --release --no-pub --dart-define-from-file=.env.geoapify.json` | Passed |
| `flutter build apk --debug --no-pub --target-platform android-arm64 --dart-define-from-file=.env.geoapify.json` | Passed; ordinary Azure-account APK |

The Stop Mode suite covers exact values, public-preview privacy, fresh copy/call,
changed stop/custody, missing contact/coordinates, launcher/clipboard failure,
403/404/429, cancelled and late reads, account/selection/background changes,
covering-route return, app resume, manual Navigate/Stop and handover hold.
It checks 320/390/840/1440 widths at normal/200% text, reachable 48-pixel actions,
keyboard and Escape/Back. The actual phone-sized test render was also inspected;
platform font rendering and touch behavior still need a phone.

The Home regression checks that Stop Mode removes the covered map, accepted
navigation fixes do not fetch more tiles while covered, and Back restores Home
with navigation still active. Existing account/Settings, command, provider and
navigation regressions are included in the full suite. The final review checks
documentation links, whitespace, scoped changes and ignored private configuration.
The coherent local delivery uses `feat(home): add focused current-stop guidance`;
the user handles publication and merge.

Only Linux and Chrome were detected; no Android installation was performed.
Local synthetic responses, fake routes and layout renders cannot establish
physical GPS, device contact/clipboard behavior or deployed operational success.

## Remaining acceptance

- [ ] Fresh authorized Azure owned-stop reads, current deployed revision,
  target-required migrations, operations discovery/capabilities and actual test task.
- [ ] Physical Android call/clipboard/directions return, text/focus/Back review
  and the existing GPS/notification/minimized/screen-off navigation checks.
- [ ] Actual collection/departure changes observed after their separately
  accepted write consumers and real seller/hub/buyer workflows.
- [ ] Existing live duty/claim write acceptance; configuration remains gated.
- [ ] User review, push and PR merge before the next selected branch.

No live credentials or actor/parcel records were supplied for this slice.
No new runtime sample mode, provider key, bearer-sharing client, travelled-location
history or fleet upload was introduced.

From the Rider repository root, review the real app in a PC phone frame:

```sh
flutter run -d linux --debug --dart-define=DEVICE_PREVIEW=true --dart-define-from-file=.env.geoapify.json
```

Use an actual owned task to open **Work this stop**. Empty live queues cannot
show this screen; synthetic task examples remain in automated tests.
