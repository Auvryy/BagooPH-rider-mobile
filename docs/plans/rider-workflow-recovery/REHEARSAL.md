# Rider rehearsal and acceptance

The November 1 selection completes PC work first. Physical Android testing is
deferred by the user. Keep this list open until its corresponding evidence exists.

## Rider app versus phone-sized Courier website

This source review compares Rider's map-disclosure code at `9d7e8cf` on
`fix/rider-route-privacy-disclosure` with the phone-responsive Courier portal
on Bagoo `main` at `f001d396b0e9ea6bfc2fdeb85ee24b66682b997e`. It covers the
Courier website, not the Buyer app. It does not claim that either client was
exercised in a real browser or on Android. The map and route-provider status
was rechecked against the active Rider source on November 1, 2026.

| Area | Rider app | Courier website on a phone | Defense-safe conclusion |
|---|---|---|---|
| Work and stops | Tasks/Home, task map, dedicated Stop Mode, pickup claim, hub departure, delivery or failed-attempt actions. | Deliveries dashboard, current-job panel, map, pickup claim, scan and outcome actions. Its source implements a mobile sidebar. | The courier work is shared. Stop Mode is a native presentation of the same authorized stop; actual phone rendering of either client remains unverified. |
| Map rendering | Android uses the bundled Leaflet document in System WebView with public OSM tiles. Linux Device Preview substitutes FlutterMap so the map stays inside its simulated phone frame. | Courier pages use browser Leaflet with public OSM tiles. | The Android map and Courier web share Leaflet and the tile source. Linux preview is a layout fallback, not Android WebView evidence. |
| Map and directions | The active map displays the saved stop or a labelled sample path using OpenStreetMap tiles. Tile coordinates and source IP address can reveal the approximate area being viewed. The default `roadRoutingProvider` is `UnavailableRoadRouting`, so Rider has no in-app road route, GPS follow or rerouting session. Explicit **External directions** opens Google Maps with the saved stop destination. | Courier maps also use OpenStreetMap tiles; the current-job directions action opens external Google Maps directions. | Both map surfaces expose tile coordinates and source IP metadata to OpenStreetMap, which can reveal the displayed area. Google Maps receives the saved destination only when the rider explicitly opens external directions. Rider does not send live GPS or a traveled-route history to Bagoo. The optional Geoapify client and route notice are not active in the default app. |
| Waybill scanning | Android `mobile_scanner` accepts a real camera result and requires one matching parcel code. There is no typed or gallery substitute in the native scan action. | `WaybillCamera` uses browser `BarcodeDetector` and `getUserMedia`; when unavailable it offers typed entry or an external scanner. The form checks the entered code against the selected waybill. | Scanning is not app-exclusive. The native camera pipeline and stricter scan-only entry are implementation differences; neither proves physical camera acceptance. |
| Delivery proof | Camera/gallery selection, protected original proof for uncertain commands, and private proof viewing in the rider's retained Trips detail. | Delivery and failed-attempt forms accept an image file. The Trips page shows recorded trip details and earnings, not the private proof viewer found in the app. A phone browser may offer camera or gallery through its file picker. | Both support proof submission. The app adds protected recovery and an in-app view of retained private evidence; do not claim that the website cannot take a photo. |
| Stop Mode and Parcel Finder | Dedicated Stop Mode includes session-only personal slot labels for an owned parcel. Labels clear on restart/sign-out and do not change server custody. | The reviewed Courier pages have a current-job/map panel; no matching personal parcel-slot labels were found. | Parcel Finder is the clearest extra rider-facing feature in the app. It is a personal organization aid, not dispatch, scanning, or custody evidence. |
| Trips and money | Trips separates recorded order status and retained evidence from Cash & remittance. The native cash screen sends pending-offer review/cancellation to the website. | Trips/Earnings combines trip history, released/pending earnings, shift cash status, earning entries, and a COD handover link; the cash page owns pending-offer review/cancellation. | Both cover trips and money, with different information grouped on screen. Some cash controls are browser-owned and reached by a handoff from the app. Show the actual returned status and ledger state; a delivery record alone is not a payout or hub receipt. |
| Messages and notifications | Assignment-bound messages and a Home notification inbox with bounded read behavior. | Courier Messages, a notification link/page, and the same courier role boundary. | Shared capabilities; source-level interaction safeguards differ. Live send/read acceptance remains open. |
| Company and handover | Company requests/offers and native missed-scan reporting/evidence/recovery entry points. | Company requests/offers in Profile and handover issue list/detail pages. | These are not app-only business workflows. Assignment acceptance, parcel custody, and authorized recovery remain server-owned. |
| Account and profile | Native Profile/Settings plus first-party website handoffs for selected account/security/recovery flows. | Responsive Profile pages for information, privacy/security/session review, assignment, and vehicle records. | Some account/security controls remain browser-owned. Do not describe a browser handoff as a native feature. |
| Retry and device behavior | Android camera lifecycle handling and an encrypted, account/API-scoped journal for uncertain commands and original proof bytes. | Browser forms use request tokens and page state; the reviewed pages do not show an equivalent protected native journal. | This is a resilience implementation difference, not full offline delivery. Rider does not provide in-app route following, server-side live tracking, or notification push in the default build. |

**Answer to “what does Rider Mobile have that the phone website does not?”**
**Session-only Parcel Finder labels inside Stop Mode** are a clear additional
rider-facing feature. Other implementation differences include Android camera
lifecycle integration, protected recovery of uncertain writes and proof, and
the private proof viewer in retained Trips. Both clients use OpenStreetMap for
map tiles and open Google Maps for external directions; Rider's default build
does not include in-app road routing or GPS-follow navigation. The website also
scans waybills and accepts proof photos, and owns pending cash-offer
cancellation and session review; the app links to those browser workflows. Core
delivery, trips, messaging, notices, cash, company, and handover operations
remain shared in the reviewed source.

Neither Courier client is a Buyer or hub client. The rider records a recipient
handoff; the server returns the applicable order status. Newer flow-version
orders may complete automatically after verified handoff. The rider does not
issue a separate buyer-confirmation command, create hub receipts, assign
final-mile work, or mark hub cash receipt/platform reconciliation. The rider
can submit a cash handover; the owning hub and ledger remain authoritative.

Sources: Rider [workspace navigation](../../../lib/features/workspace/presentation/workspace_shell.dart),
[Android/PC map renderer selection](../../../lib/features/navigation/presentation/leaflet_delivery_map.dart),
[Linux Device Preview map fallback](../../../lib/features/navigation/presentation/native_delivery_map.dart),
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
[Courier map](https://github.com/Auvryy/BagooPH/blob/f001d396b0e9ea6bfc2fdeb85ee24b66682b997e/resources/js/Components/CourierJobMap.tsx),
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
> Rider adds session-only Parcel Finder labels, Android camera and lifecycle
> integration, protected recovery of uncertain submissions, and private proof
> viewing in Trips. Both clients use OpenStreetMap tiles and send the saved stop
> to Google Maps only when external directions are opened. Rider's default build
> has no in-app road routing or GPS-follow navigation. PC checks are recorded.
> Release signing, deployed cross-role acceptance, and physical Android
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
   clears with the app session and never changes server custody. Both Rider map
   renderers request OpenStreetMap tiles for the displayed area. Tile
   coordinates and source IP address can reveal the approximate area to the
   provider. The default road-routing provider is unavailable, so there is no
   in-app GPS follow or rerouting. When the rider explicitly opens External
   directions, Google Maps receives the saved stop address or coordinates. The
   Android client also uses the native scanner lifecycle and protects the
   original request and proof when a command
   outcome is uncertain. It does not claim full offline delivery.
4. **Relationship to web — 45 seconds.** Courier web already includes queues,
   maps, camera scanning, proof upload, Trips/Earnings, Messages, notifications,
   cash handovers, company requests, and handover issues. Both clients use
   OpenStreetMap tiles and open external directions in Google Maps. Core courier
   operations remain shared. These checks do not measure delivery speed,
   accuracy, or user satisfaction; claim gains only if a separate field study
   supports them.
5. **Evidence and limits — 60 seconds.** The latest full serial Flutter suite
   passed **700 tests, 7 skipped, zero failures** at local test checkout
   `d04cb54` (runtime `a9b972d`) in 4m26s; this commit is not pushed.
   `flutter analyze --no-pub` reported no issues in 7.8s. The runtime code was
   unchanged from `a9b972d`. A separate headless Rider client scenario passed
   against the pinned Bagoo kernel, including lost-response recovery, paid COD
   completion, cash separation, retained private proof and failed-return /
   reassignment. Focused evidence also includes 42 command/workflow/outcome
   tests at `3839de6`, 20 proof-recovery/Trips tests at `cbd6b21`, 20 Parcel
   Finder tests at `d42c948`, and six map-disclosure checks at
   `9d7e8cf`/`039d40d`. Flutter analysis is clean after the theme change. The
   current arm64-targeted debug APK was built from published revision `8b50401`
   with the same runtime code. An arm64-targeted profile preview was built from
   published branch head `82f3bc6` (runtime `a9b972d`). Both passed PC archive,
   metadata and v2 debug-signature checks, use the scaffold package ID, and were
   not installed. Neither establishes release signing, Azure deployment,
   cross-role production behavior, or physical Android camera/lifecycle
   acceptance. See
   [current APK evidence](../../ANDROID_RELEASE.md).

### Likely questions

- **What does the app add beyond the phone website?** Rider adds session-only
  Parcel Finder labels in Stop Mode, native camera lifecycle handling, protected
  recovery for uncertain submissions, and private proof viewing in Trips. Both
  clients support waybill scanning and proof upload.
- **Does Rider provide in-app navigation?** Not in the default build. The active
  map shows a saved stop or sample path, but `roadRoutingProvider` is
  `UnavailableRoadRouting`; there is no GPS follow or rerouting session.
- **What location or destination data leaves the app?** OpenStreetMap tile
  requests include the displayed area’s tile coordinates and source IP address,
  which can reveal its approximate location to the tile provider. If the rider
  explicitly opens External directions, Google Maps receives the saved stop
  address or coordinates. Rider sends no live GPS feed or traveled-route history
  to Bagoo. The optional Geoapify route client is not wired into the default
  provider path. The public OSM tile service is best-effort without an SLA, so
  this is a bounded demo provider, not a production availability promise; its
  official policy and the current provider follow-up are recorded in the
  [street-map plan](../rider-street-map/README.md).
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
- **Is it ready for a live Android defense demo?** Current arm64-targeted debug
  and profile APKs are built and verified on the PC, but neither has been
  installed. Both use the scaffold application ID and debug signing. Approved release
  identity/signing, deployed cross-role acceptance, and physical Android
  acceptance remain open, so a live-phone demo is not yet accepted.

Present device-dependent steps only after the approved account, isolated owned
resources, deployment, and physical Android checks in the acceptance table are
complete. Until then, describe them as implemented source behavior with PC
evidence, not as an accepted live phone demonstration.

## Current PC evidence and open gates

- The latest full serial Flutter suite passed **700 tests, 7 skipped, zero
  failures** in 4m26s at local test checkout `d04cb54`, exercising runtime
  change `a9b972d`. This local test/documentation update is not pushed; runtime
  code was unchanged. `flutter analyze --no-pub` reported no issues in 7.8s.
  This is PC-only unit/widget evidence; physical Android gates remain open.
- Runtime code at Rider revision `9d7e8cf` and test revision `039d40d` passed
  six focused PC checks serially: saved/sample map disclosures, default
  route-provider status, Google Maps handoff disclosure, and both notices at
  320 px with 200% text. `flutter analyze --no-pub` found no issues.
  `git diff --check` and changed-document local-link/fence
  checks passed. No phone or emulator was used.
- The isolated company API check passed **1/1** against Bagoo `9e58312` in 50
  seconds. It used SQLite `:memory:` and a headless Dart client, verifying
  uncertain-request replay, stale-offer rejection, exact consent/placement,
  duty still off, and no delivery checkpoint or COD account.
- The focused photo-recovery suite passed **7/7** at Rider head `f17309c`. It
  covers scoped restart and lost-picker handling with a simulated picker, not
  physical Android lifecycle behavior.
- At Rider revision `cbd6b21`, the combined proof-recovery and Trips PC suites
  passed **20/20** serially: 7 photo-service, 4 protected-proof-store and 9
  Trips widget cases. Coverage includes scoped simulated lost-picker recovery,
  encrypted/hash-bound proof retention, private viewer clearing on background,
  reopening after resume and logout cleanup. This is PC-only evidence, not
  physical Android acceptance; see [verification](VERIFICATION.md).
- At the current Rider branch revision `3839de6`, the focused parcel
  command/workflow/outcome suites passed **42/42** serially. They cover exact
  uncertain-command replay, proof/COD validation, stale-access rejection,
  correction after server field errors, and 320/840 px outcome forms at 200%
  text. It complements the current full-suite result and does not clear the
  open Android and deployment gates; see [parcel verification](../rider-orders-delivery-trips/VERIFICATION.md).
- At Rider revision `6a0ab47`, the headless native Rider-to-kernel scenario
  passed **1/1** against Bagoo `9e58312`. It uses synthetic data and SQLite
  `:memory:`; it does not establish Azure or physical Android acceptance. The
  loopback fixture ran separately from the full test suite. The Bagoo worktree
  stayed unchanged; see
  [parcel verification](../rider-orders-delivery-trips/VERIFICATION.md).
- At Rider branch head `d42c948`, the focused Parcel Finder suite passed
  **20/20** serially: 13 state/controller/provider tests and 7 picker/Stop Mode
  widget tests. It covers account/assignment scoping, cleanup, fresh ownership,
  duplicate taps, accessible controls and 320 px at 200% text. These PC checks do
  not establish physical Android layout, camera or lifecycle acceptance.
- The current arm64-targeted debug APK was built from published revision
  `8b50401` (runtime `a9b972d`). It is 176,214,087 bytes, with SHA-256
  `b82d9a66e19803e248e9f6004a6a7837d562743bf8d651549ed3aae5e84a8abe`.
  Archive integrity, package/version/SDK metadata, debuggable state, and the
  single-signer APK v2 signature passed PC checks. It was not installed; see
  [packaging evidence](../../ANDROID_RELEASE.md).
- At the GitHub ref fetch immediately before the November 1 rehearsal refresh,
  Rider `main` was `4367331`; the published defense branch was `3e6131c`, 57
  commits ahead and 0 behind. The 699-test run was at `fc99a02`; its runtime is
  present in the published branch. Bagoo web `main` remains `f001d396`; the
  Wallet/handover source branch `9e58312` is 2 commits ahead of main, not merged
  or deployment evidence.
- The current arm64-targeted profile preview was built from published branch
  head `82f3bc6` (runtime `a9b972d`). It is 77,606,440 bytes, with SHA-256
  `c6706a114cac8807265b49a67890e6ceb260896cbad222015e11c5f361e9e0c6`.
  Archive, package/version/SDK metadata and v2 `Android Debug` signing passed
  PC checks. It is debuggable, uses the scaffold package ID, and was not
  installed. Flutter targeted arm64, while plugins retain libraries for three
  Android ABIs. The published defense branch was 58 commits ahead and 0 behind
  Rider `main` `4367331` at build time.
- At an earlier build-verification checkpoint, the branch was recorded at
  `e9fb7e3`, 34 commits ahead and 0 behind main. That is historical ref evidence.
- A PC `--release` build request at `e0aa20e` stopped before artifact generation
  because the approved package ID and local signing settings were absent. The
  November 1 workspace check also found no `RIDER_APPLICATION_ID`,
  `android/key.properties`, or default release keystore. This confirms the
  release gate remains open; it does not produce a distributable APK.
- Azure deployment/cross-role acceptance, approved release identity/signing,
  and physical Android lifecycle acceptance remain open. Keep the phone check
  deferred; PC evidence does not clear these gates.

### PC-only presentation fallback

If an Android device is unavailable during the defense, present the recorded
evidence in this order without implying a live-device demonstration:

**Map preview limit:** Linux Device Preview uses the FlutterMap fallback so the
map stays inside the simulated phone frame. Android uses the bundled Leaflet
document in System WebView. The Linux preview supports layout/workflow review,
but it does not verify Android's map renderer or lifecycle. Local Leaflet runtime
checks cover the bundled document separately.

1. Give the four-minute explanation above and show the source-backed
   [app-versus-website comparison](#rider-app-versus-phone-sized-courier-website).
   Make clear that the website already supports scanning and proof upload; the
   clearest extra rider-facing feature is session-only Parcel Finder labels.
2. Show the PC evidence above with revisions attached: the latest full suite
   passed 700 tests with 7 skips at local test head `d04cb54` (runtime
   `a9b972d`; not pushed); the current arm64 debug APK at `8b50401` has the
   same runtime code and remains debug-signed and uninstalled. The current
   profile preview at `82f3bc6` is
   also debug-signed and uninstalled. None of these establishes hardware
   behavior.
3. If asked to demonstrate an operational transaction, explain that Azure and
   cross-role acceptance are separate open gates. Do not substitute sample data
   or imply that a PC test changed a live assignment, order, proof or cash record.
4. Close with the acceptance table below. State that physical Android camera,
   lifecycle, permissions and layout checks remain deferred.

Suggested wording: “Today I can show the implemented Rider workflow and its PC
verification. Physical Android and deployed cross-role acceptance are still
pending, so I am not presenting this as an accepted live-phone demo.”

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
| Security/recovery | First-party website sign-in, session review/revocation and authorized restricted recovery through `/custody-recovery/sign-in`. Returning requires fresh native permission; links do not clear restrictions. |
| Phone lifecycle | Camera denied/cancel/retry, interrupted picker/process kill, app restore, logout/account change, keyboard and actual Android Back. Deferred. |
| Evidence freeze | Exact APK, source and deployed revision, selected resources and results retained; final rehearsal before the November 20 freeze. |

Use the existing narrow acceptance procedures for each action family. No build
flag is evidence that these checks passed. No notification push, live tracking,
turn-by-turn routing or full offline delivery is claimed by this delivery.
