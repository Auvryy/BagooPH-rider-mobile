# Rider rehearsal and acceptance

The November 1 selection completes PC work first. Physical Android testing is
deferred by the user. Keep this list open until its corresponding evidence exists.

## Rider app versus phone-sized Courier website

This source review compares Rider app source at `9886648` with the
phone-responsive Courier portal on the live Bagoo `main` revision
`f001d396b0e9ea6bfc2fdeb85ee24b66682b997e`. It covers the Courier website, not
the Buyer app. It does not claim that either client was exercised in a real
browser or on Android. The Rider comparison snapshot was branch head `5c2e2a8`;
it contains documentation updates after the reviewed app source and does not
change that source. At that snapshot, the published Rider branch was 18 commits
ahead and 0 behind Rider `main` at `4367331`.

| Area | Rider app | Courier website on a phone | Defense-safe conclusion |
|---|---|---|---|
| Work and stops | Tasks/Home, task map, dedicated Stop Mode, pickup claim, hub departure, delivery or failed-attempt actions. | Deliveries dashboard, current-job panel, map, pickup claim, scan and outcome actions. Its source implements a mobile sidebar. | The courier work is shared. Stop Mode is a native presentation of the same authorized stop; actual phone rendering of either client remains unverified. |
| Waybill scanning | Android `mobile_scanner` accepts a real camera result and requires one matching parcel code. There is no typed or gallery substitute in the native scan action. | `WaybillCamera` uses browser `BarcodeDetector` and `getUserMedia`; when unavailable it offers typed entry or an external scanner. The form checks the entered code against the selected waybill. | Scanning is not app-exclusive. The native camera pipeline and stricter scan-only entry are implementation differences; neither proves physical camera acceptance. |
| Delivery proof | Camera/gallery selection, protected original proof for uncertain commands, and private proof viewing in the rider's retained Trips detail. | Delivery and failed-attempt forms accept an image file. The Trips page shows recorded trip details and earnings, not the private proof viewer found in the app. A phone browser may offer camera or gallery through its file picker. | Both support proof submission. The app adds protected recovery and an in-app view of retained private evidence; do not claim that the website cannot take a photo. |
| Stop Mode and Parcel Finder | Dedicated Stop Mode includes session-only personal slot labels for an owned parcel. Labels clear on restart/sign-out and do not change server custody. | The reviewed Courier pages have a current-job/map panel; no matching personal parcel-slot labels were found. | Parcel Finder is the clearest extra rider-facing feature in the app. It is a personal organization aid, not dispatch, scanning, or custody evidence. |
| Trips and money | Trips separates recorded order status and retained evidence from Cash & remittance. The native cash screen sends pending-offer review/cancellation to the website. | Trips/Earnings combines trip history, released/pending earnings, shift cash status, earning entries, and a COD handover link; the cash page owns pending-offer review/cancellation. | Both cover trips and money, with different information grouped on screen. Some cash controls are browser-owned and reached by a handoff from the app. Show the actual returned status and ledger state; a delivery record alone is not a payout or hub receipt. |
| Messages and notifications | Assignment-bound messages and a Home notification inbox with bounded read behavior. | Courier Messages, a notification link/page, and the same courier role boundary. | Shared capabilities; source-level interaction safeguards differ. Live send/read acceptance remains open. |
| Company and handover | Company requests/offers and native missed-scan reporting/evidence/recovery entry points. | Company requests/offers in Profile and handover issue list/detail pages. | These are not app-only business workflows. Assignment acceptance, parcel custody, and authorized recovery remain server-owned. |
| Account and profile | Native Profile/Settings plus first-party website handoffs for selected account/security/recovery flows. | Responsive Profile pages for information, privacy/security/session review, assignment, and vehicle records. | Some account/security controls remain browser-owned. Do not describe a browser handoff as a native feature. |
| Retry and device behavior | Android camera lifecycle handling and an encrypted, account/API-scoped journal for uncertain commands and original proof bytes. | Browser forms use request tokens and page state; the reviewed pages do not show an equivalent protected native journal. | This is a resilience implementation difference, not full offline delivery. No offline delivery, turn-by-turn routing, live tracking, or notification push is claimed. |

**Answer to “what does Rider Mobile have that the phone website does not?”** The
best-supported user-facing example is **session-only Parcel Finder labels inside
Stop Mode**. The strongest implementation differences are Android camera
lifecycle integration, protected recovery of uncertain writes/proof, and the
private proof viewer in retained Trips. The website also scans waybills and
accepts proof photos, and owns pending cash-offer cancellation and session
review; the app links to the relevant browser workflows. Core delivery, trips,
messaging, notices, cash, company, and handover workflows are shared in the
reviewed source.

Neither Courier client is a Buyer or hub client. The rider records a recipient
handoff; the server returns the applicable order status. Newer flow-version
orders may complete automatically after verified handoff. The rider does not
issue a separate buyer-confirmation command, create hub receipts, assign
final-mile work, or mark hub cash receipt/platform reconciliation. The rider
can submit a cash handover; the owning hub and ledger remain authoritative.

Sources: Rider [workspace navigation](../../../lib/features/workspace/presentation/workspace_shell.dart),
[Stop Mode](../../../lib/features/home/presentation/stop_mode_page.dart),
[Parcel Finder](../../../lib/features/parcel_finder/presentation/parcel_finder_card.dart),
[scanner](../../../lib/features/parcels/presentation/waybill_scanner_page.dart),
[command journal](../../../lib/features/home/data/command_journal.dart),
[photo draft recovery](../../../lib/features/parcels/data/parcel_photo_service.dart),
[encrypted proof storage](../../../lib/core/commands/protected_proof_store.dart),
[session lifecycle](../../../lib/features/auth/data/auth_repository.dart),
[proof viewer](../../../lib/features/trips/presentation/trip_detail_page.dart),
[cash](../../../lib/features/cash/presentation/cash_page.dart),
[company](../../../lib/features/company/presentation/company_page.dart),
[messages](../../../lib/features/messages/presentation/messages_page.dart),
[notifications](../../../lib/features/notifications/presentation/notifications_page.dart),
and [handover](../../../lib/features/handover/presentation/handover_issues_page.dart).
Bagoo sources are pinned to [Courier Deliveries](https://github.com/Auvryy/BagooPH/blob/f001d396b0e9ea6bfc2fdeb85ee24b66682b997e/resources/js/Pages/Courier/Deliveries.tsx),
[browser scanner](https://github.com/Auvryy/BagooPH/blob/f001d396b0e9ea6bfc2fdeb85ee24b66682b997e/resources/js/Components/WaybillCamera.tsx),
[responsive portal layout](https://github.com/Auvryy/BagooPH/blob/f001d396b0e9ea6bfc2fdeb85ee24b66682b997e/resources/js/Layouts/CourierLayout.tsx),
[responsive navigation](https://github.com/Auvryy/BagooPH/blob/f001d396b0e9ea6bfc2fdeb85ee24b66682b997e/resources/js/Components/CourierSidebar.tsx),
[Trips/Earnings](https://github.com/Auvryy/BagooPH/blob/f001d396b0e9ea6bfc2fdeb85ee24b66682b997e/resources/js/Pages/Courier/Earnings.tsx),
[Messages](https://github.com/Auvryy/BagooPH/blob/f001d396b0e9ea6bfc2fdeb85ee24b66682b997e/resources/js/Pages/Courier/Messages.tsx),
[Profile](https://github.com/Auvryy/BagooPH/blob/f001d396b0e9ea6bfc2fdeb85ee24b66682b997e/resources/js/Pages/Courier/Profile.tsx),
[company requests](https://github.com/Auvryy/BagooPH/blob/f001d396b0e9ea6bfc2fdeb85ee24b66682b997e/resources/js/Components/CourierCompanyRequests.tsx),
[COD cash UI](https://github.com/Auvryy/BagooPH/blob/f001d396b0e9ea6bfc2fdeb85ee24b66682b997e/resources/js/Components/CodCashUI.tsx),
[notifications layout](https://github.com/Auvryy/BagooPH/blob/f001d396b0e9ea6bfc2fdeb85ee24b66682b997e/resources/js/Layouts/NotificationLayout.tsx),
and [handover issues](https://github.com/Auvryy/BagooPH/blob/f001d396b0e9ea6bfc2fdeb85ee24b66682b997e/resources/js/Pages/Handover/Index.tsx).

## Thesis defense talk track

### Short spoken summary

> BagooPH Rider Mobile is a native Flutter client for courier pickup and
> final-mile work. It brings the rider's authorized task, next stop, scan, and
> delivery evidence into a field-focused workflow. The backend remains the
> authority for assignment, custody, order status, and cash records. The
> phone-responsive Courier website already supports the shared business flows;
> the app adds Stop Mode, session-only Parcel Finder labels, Android camera and
> lifecycle integration, protected recovery of uncertain submissions, and
> private proof viewing in Trips. The latest recorded PC checks passed, while
> release signing, deployed cross-role acceptance, and physical Android
> acceptance are still pending.

### Four-minute explanation

1. **Problem and scope — 30 seconds.** A rider needs to know which parcel they
   are authorized to handle, what stop comes next, and what evidence is required.
   This app serves the courier role; it is not a Buyer or hub application.
2. **End-to-end responsibility — 50 seconds.** A rider may claim an available
   seller pickup and record the actual scan. The origin hub records intake; the
   destination hub assigns final-mile work. The assigned rider records recipient
   handoff, proof, and exact COD when applicable. The server returns the order
   status. Failed delivery keeps the rider responsible until the hub records
   return; cash remittance remains a separate handoff.
3. **Native contribution — 55 seconds.** Stop Mode gathers the authorized stop
   details into one screen. Parcel Finder adds a personal compartment label that
   clears with the app session and never changes server custody. The Android
   client uses the native scanner lifecycle and protects the original request
   and proof when a command outcome is uncertain. It does not claim full offline
   delivery.
4. **Relationship to web — 45 seconds.** Courier web already includes queues,
   maps, camera scanning, proof upload, Trips/Earnings, Messages, notifications,
   cash handovers, company requests, and handover issues. The thesis contribution
   is the native field workflow and recovery behavior, not exclusive access to
   these courier operations. These app checks do not measure delivery speed,
   accuracy, or user satisfaction; claim gains only if a separate field study
   supports them.
5. **Evidence and limits — 60 seconds.** The serial Flutter suite passed 693
   tests with 7 skips, analysis reported no issues, and the isolated headless
   parcel check passed 1/1. The available APK is a debug build. These checks do
   not establish a signed release, Azure deployment, cross-role production
   behavior, or physical Android camera/lifecycle acceptance.

### Likely questions

- **What does the app add beyond the phone website?** The clearest user-facing
  example is session-only Parcel Finder labels inside Stop Mode. Other
  implementation additions include native camera lifecycle handling, protected
  recovery of uncertain submissions, and private proof viewing in Trips. The
  website also scans and uploads proof photos.
- **Does delivery still work without internet?** No full offline delivery is
  claimed. The journal retains the original uncertain request and proof so the
  app can reconcile or retry that same operation when connectivity returns.
- **What if Android stops the app while a proof photo is being selected?** The
  native picker path records the exact API/account/task/action/version context.
  It can recover one matching photo for up to 24 hours into encrypted app-owned
  storage. The restored image stays a draft and never submits an outcome by
  itself. The focused PC suite passed 7/7 using a simulated picker; actual
  Android kill/resume acceptance remains open.
- **What happens to an uncertain request after sign-out or an account change?**
  Its encrypted journal is scoped to the original API and account, and the
  original proof remains protected. The app checks that saved request before a
  new one can replace it. A retry uses the same request key and unchanged
  evidence; no other account inherits it.
- **Does the rider confirm that the buyer received the parcel?** The rider
  records the handoff. The backend returns the applicable status; newer
  flow-version orders may complete automatically. There is no separate
  Rider-issued buyer-confirmation command.
- **How do you know the app improves delivery performance?** The current
  evidence verifies client behavior and selected isolated API flows. It does
  not measure delivery speed, accuracy, or satisfaction; those gains require a
  separate field study.
- **Is it ready for a live Android defense demo?** PC review evidence is ready.
  Release identity/signing, deployed cross-role acceptance, and physical Android
  acceptance remain open; the debug APK is not a distributable release.

Present device-dependent steps only after the approved account, isolated owned
resources, deployment, and physical Android checks in the acceptance table are
complete. Until then, describe them as implemented source behavior with PC
evidence, not as an accepted live phone demonstration.

## Current PC evidence and open gates

- The full serial Flutter suite passed **693 tests with 7 skips** at Rider
  source revision `f9dd4cf`; analysis reported no issues. The separate headless
  parcel check passed **1/1** against Bagoo `9e58312`.
- The focused photo-recovery suite passed **7/7** at Rider head `f17309c`. It
  covers scoped restart and lost-picker handling with a simulated picker, not
  physical Android lifecycle behavior.
- The Parcel Finder/Stop Mode widget suite passed **7/7** at Rider head
  `5836658`: five viewport/text-scale setups, accessible 48px slot controls,
  keyboard activation, duplicate-save protection, and the owned Stop Mode flow.
  These are widget checks; physical Android layout and camera acceptance remain
  open.
- A local arm64-targeted profile build produced
  `build/app/outputs/flutter-apk/app-profile.apk` (**64,285,631 bytes**;
  SHA-256
  `625fa56617f1fd5ad3c41e9b5c822357dc6eafb4118bcb8df8c46511f5fb7da4`). APK
  archive CRC and Android v2 debug signature verified. The package uses the
  scaffold application ID; it was not installed or run on a phone.
- The current debug APK is `build/app/outputs/flutter-apk/app-debug.apk`,
  SHA-256 `42ce7a5d1493fa60b9dee7b670094e5222b1ad67ed2d5771459053ffa0cbfae6`.
  It is a debug build, not a signed release, and was not installed or run on a
  phone.
- At the comparison snapshot, live GitHub refs showed Rider branch `5c2e2a8`
  **18 ahead, 0 behind** Rider `main` `4367331`. Bagoo web `main` is `f001d396`;
  the separate Wallet / handover source branch `9e58312` is **2 ahead, 0 behind**
  and is not merged or deployment evidence.
- Azure deployment/cross-role acceptance, approved release identity/signing,
  and physical Android lifecycle acceptance remain open. Keep the phone check
  deferred; PC evidence does not clear these gates.

| Check | Evidence needed |
|---|---|
| Account access | Real approved native login and restored session; pending/restricted accounts retain their restrictions; no substitute production accounts. |
| Company | Fresh current directory/request/offer, exact terms and explicit consent; no accidental duty activation or duplicate acceptance. |
| Pickup | Actual matching/wrong scan, one claim/collection, named origin-hub receipt; no client-created intake. |
| Version-two COD | Authorized hub departure, correct recipient/proof and counted cash; committed `completed` order visible cross-role. |
| Paid Wallet | Original paid handoff with no COD collection, original recipient/private proof after delivery and replay, foreign proof denied. Source fixes and backend regressions are on `fix/rider-wallet-trip-evidence`; merge/deploy and controlled owned-resource acceptance are still required. |
| Failure/return | One recorded failed attempt, truthful next hub/retry authority and actual hub receipt; preserve all prior evidence. |
| Cash/shift | Offer leaves held cash unchanged; independent hub receipt updates the ledger and closure decision; cancellation remains separately authorized. |
| Messages/notices | Actual phase-bound send, displayed read boundaries and later arrivals remaining unread; opening links alone is not write acceptance. |
| Security/recovery | First-party website sign-in, session review/revocation and authorized restricted recovery. Returning requires fresh native permission; links do not clear restrictions. |
| Phone lifecycle | Camera denied/cancel/retry, interrupted picker/process kill, app restore, logout/account change, keyboard and actual Android Back. Deferred. |
| Evidence freeze | Exact APK, source and deployed revision, selected resources and results retained; final rehearsal before the November 20 freeze. |

Use the existing narrow acceptance procedures for each action family. No build
flag is evidence that these checks passed. No notification push, live tracking,
turn-by-turn routing or full offline delivery is claimed by this delivery.
