# Notifications verification record

Verified October 19, 2026 on `feat/home-durable-notices`, based on merged Rider
main `cc3a65f`. The selected client implementation is complete. Azure delivery,
deployed read acceptance and physical Android checks remain open.

## Current results

| Check | Result | Evidence scope |
|---|---|---|
| Selected notification tests | **45 passed** | 32 model/command/controller and 13 UI checks |
| Full `flutter test --no-pub` | **539 passed, 4 expected skips; exit 0** | Existing account, Settings, maps, parcel, Trips, Messages and new inbox regressions |
| `flutter analyze --no-pub` | **No issues; exit 0** | Final Dart source and tests |
| Isolated native Laravel check | **1 passed; exit 0** | Real native Dio/session/secure journal and backend kernel over SQLite `:memory:` |
| Ordinary Linux debug build | **Passed; exit 0** | Normal Azure entrypoint, optional phone frame and existing local map configuration |
| Ordinary Android debug APK | **Passed; exit 0** | Normal Azure entrypoint; no notification-test configuration |
| Source/diff/privacy and Markdown links | **Passed** | Selected files; private guide/configuration and handoff remain outside Git |

The build commands used `--no-pub` and the existing ignored project-local
configuration. No new dependency, key, platform permission or backend change was
introduced. Runtime tests were headless; no visible app launch or phone install
was performed for this slice.

## Behavior proved

- Server unread aggregate is independent of loaded page length; offset overlaps
  deduplicate, page failures retain readable rows and loading stops at 200 rows.
- Single reads use an empty JSON object, bulk reads use the exact rendered IDs.
  Cached offscreen rows, changed render revisions and later same-tick arrivals
  cannot enter an earlier read intent. Opening a notice alone does not read it.
- Secure storage precedes POST. Uncertain/replayed/conflicting/expired/foreign
  reads preserve truthful state and original UUID/body. Journal namespaces isolate
  accounts, API origins, work, Messages and Notifications, preserving old keys.
- Fresh task links enter existing Stop Mode and recheck owned detail without
  starting navigation or a read. Unknown/null/malformed targets stay readable;
  denied or late target responses cannot open stale detail.
- Linked cash/account records use exact native paths and checked IDs. Cash uses
  integer-cent facts with no offers, receipts, reconciliation writer or earnings.
  Linked cash refresh after resume was checked with a changed returned amount.
- Hidden routes and background/account/access changes cancel reads, clear private
  state and invalidate rendered IDs. Resume revalidates through the existing
  workspace refresh loop; quota cooldown prevents repeated requests.
- Real-font renders were inspected at 320/200%, 375/100%, 844 landscape,
  900/200% and 1200 desktop widths, plus linked cash. Native 48dp controls,
  screen-reader names, keyboard Enter, scrolling and Back were verified locally.

The [native check](LOCAL_KERNEL.md) independently inspected saved notification
rows and three original committed read commands. Recipient/source retry did not
duplicate a notice, the later arrival stayed unread until its explicit original
read, foreign reads rejected and parcel custody/cash facts were unchanged.
An invalid test-expiry interval and a frozen-clock cleanup limit were corrected
in the disposable fixture; the final complete native run passed with normal
request limits enabled.

## Source and external limits

Initial source: `b476f44aecf1c78aeaccd914d3c5456874ad9436`. Native kernel snapshot:
`c590ae2a9491020cd1266399b4ad304b888b71df`. Final source-only review:
`3f7691e8a7eda28196d5ded351c464abbe5d0c3f`; the added buyer-return type/browser
snapshot helpers do not change the selected native protocol. The other owner's
ongoing website work was preserved. No new Azure deployment verification or
production notification read was performed.

`NOTIFICATIONS_WRITES_VERIFIED` remains false pending the separate deployed read
gate. Actual Azure scheduler/durable delivery, cross-role parity and physical
Android lifecycle/accessibility checks remain unchecked in the
[API checklist](../../api/NOTIFICATIONS_NEEDS.md) and [acceptance list](TESTING.md).
These results do not complete the full M12 baseline or the other OPS batches.
