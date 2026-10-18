# Assignment Messages verification

Reviewed October 18, 2026. Branch `feat/rider-assignment-messages`, from merged
Rider main `8d68566`.

## Reviewed and exercised source

The review began at backend `a36f468726bcba9e2871056fcb6232f8388770d9`.
The native runner archived the newer committed snapshot
`eeadbcecda7ed6ce7bb8c76f6346327bbfcdbe55` after the website's address-book merge.
The selected courier/messaging services, message controller, owning Chat
controller, native routes and courier tests have no diff between those revisions.
This Rider work changed no website branch, files or production data. Neither
revision establishes Azure's actual deployment.

| Requirement | Actual evidence | Result |
|---|---|---|
| Exact authorized identity | String IDs through signed 64-bit maximum, full phase/assignment/participant tuple and sender validation | Contract and real kernel passed |
| Paged resources | Newest-first history, bounded pages, stable-ID deduplication, search explicitly scoped to loaded chats | Contract/controller/widget passed |
| Protected original intent | Separate account/API secure journal, normalized text and original UUID, persist before dispatch, work/message command-kind isolation | Unit and native secure-storage reconstruction passed |
| Uncertain recovery | Lost committed send, retained replay, unknown read before dispatch and explicit original-key retry | Unit and real kernel passed |
| Expiry | Expired retained lookup remains readable; unknown expired intent cannot start another write | Unit passed |
| Current recipient/permission | Seller pickup, buyer final mile, read-only phase after actual hub intake, foreign thread/boundary denial | Unit and real kernel passed |
| Displayed reads | Rendered incoming boundary, obsolete/offstage/background rejection, late arrival unread and monotonic committed read state | Controller/widget and real kernel passed |
| Refresh and cancellation | One shared foreground poll, surface leases, actual cancellable authenticated GET and shared request/429 budget | Local tests passed |
| Drafts and scrolling | Original-thread drafts, validation recovery, safe partial-list absence, preserved scroll anchor, confirmed inbox preview and cancelled-page loading recovery | Controller/widget passed |
| Current-stop entry | Returned identity resolution, second stop revalidation, actual Stop Mode navigation and account-loss private route removal | Controller and route widget passed |
| Responsive presentation | Actual bundled fonts/icons; 320/375 phones, 844/900 landscape, 1200 desktop; 200% text, simulated keyboard, reduced motion and 48dp send | Rendered and locally inspected |
| Ordinary native builds | Azure-entry Linux/Android builds after the integration target | Final receipts pending |
| Azure and owning website parity | Actual deployed commit/migrations, fresh authorized session, isolated seller/buyer cases and independent readbacks | Not established |
| Physical Android | Actual keyboard, Back, background/resume, account changes and secure recovery on hardware | Not established |

## Recorded checks

- Full Flutter suite: **473 passed, four expected skips**, in 2 minutes 17 seconds.
  Skips: three opt-in historical redesign renders and the alternate-API
  configuration case when no API override is supplied.
- Initial selected Messages/workspace/duty/claim regression: **70 passed**.
- Additional actual owned-stop route/account cleanup: **one passed**.
- Native Linux → isolated real Laravel kernel: **one comprehensive scenario
  passed**, in 1 minute 48 seconds after compilation, with normal limits enabled.
  Owning seller/buyer reply actions, read-only inbox payloads and saved rows
  agree: two intended sends and three read commands persist. Chat creates no
  delivered checkpoint or final-mile outcome.
- PHP/Node fixture syntax and Git whitespace checks passed. Final analysis and
  ordinary build receipts are recorded when complete.

The native fixture's deliberate duty, claim, collection and hub intake run only
in SQLite `:memory:` to establish valid phases. They are not Azure or physical
pickup acceptance. The web history action that acknowledges on GET is not used.
Temporary sandbox directories were removed after the successful run.

The stop shortcut searches at most five conversation pages. Missing matches
remain unavailable and point back to paged Messages; no thread is guessed. See
the optional improvement in [the API checklist](../../api/MESSAGES_NEEDS.md).

## Remaining activation

`MESSAGES_WRITES_VERIFIED` remains false in ordinary configuration. Parcel writes
remain independently disabled; accepted duty/claim activation is unchanged.
GET browsing uses real authorized v1 data. Fixtures cannot activate these gates.
No additional provider key is needed for chat.

Follow [TESTING.md](TESTING.md), [LOCAL_KERNEL.md](LOCAL_KERNEL.md) and the
[API checklist](../../api/MESSAGES_NEEDS.md). The cumulative external handoff
retains both earlier parcel/Trips acceptance and these Messages requests. Do not
repeat previously accepted production claims to manufacture conversations.
