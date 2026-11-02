# Rider rehearsal and acceptance

The November 1 selection completes PC work first. Physical Android testing is
deferred by the user. Keep this list open until its corresponding evidence exists.

## Rider app versus phone-sized Courier website

This source review compares Rider runtime and Android manifest code at
`daacf85` on `fix/rider-route-privacy-disclosure`; later branch commits only
update documentation. It compares that code with the
phone-responsive Courier portal on Bagoo `main` at
`f001d396b0e9ea6bfc2fdeb85ee24b66682b997e`. The remote Bagoo main and review
branch refs were rechecked November 2, 2026. This covers the Courier website,
not the Buyer app. It does not claim that either client was exercised in a real
browser or on Android. The separate Bagoo review branch
`fix/rider-wallet-trip-evidence` at `9e58312` fixes the native Wallet
recipient/private-proof response, but remains unmerged and is used only for
isolated PC compatibility checks; no deployed Wallet acceptance is claimed.
The map and route-provider status was rechecked against current Rider source on
November 2, 2026.

| Area | Rider app | Courier website on a phone | Defense-safe conclusion |
|---|---|---|---|
| Navigation shell | On phones, four persistent bottom tabs: Tasks, Trips, Messages and Profile. Notifications open from Tasks/Home; cash is nested in Profile; handover issue reporting opens from Tasks/Home or Stop Mode. | On phones, a responsive sidebar drawer with Dashboard, Trips, Messages, Profile and Handover issues; notifications have a separate header entry, and cash handovers are linked from Trips/Earnings. | Both expose the courier workflows. The app emphasizes bottom-tab navigation; the site uses a drawer and separate pages. This is a navigation difference, not an app-only business capability. |
| Work and stops | Tasks/Home, task map, dedicated Stop Mode, pickup claim, hub departure, delivery or failed-attempt actions. | Deliveries dashboard, current-job panel, map, pickup claim, scan and outcome actions. Its source implements a mobile sidebar. | The courier work is shared. Stop Mode is a native presentation of the same authorized stop; actual phone rendering of either client remains unverified. |
| Map rendering | Android uses the bundled Leaflet document in System WebView with public OSM tiles. Linux Device Preview substitutes FlutterMap so the map stays inside its simulated phone frame. | Courier pages use browser Leaflet with public OSM tiles. | The Android map and Courier web share Leaflet and the tile source. Linux preview is a layout fallback, not Android WebView evidence. |
| Map and directions | The map displays the saved stop or a labelled sample path using OpenStreetMap tiles. The current Android build does not declare location permissions, and the Home location-controller code is not wired to the Home surface. The default `roadRoutingProvider` is `UnavailableRoadRouting`, so Rider has no active in-app route, GPS follow or rerouting session. **External directions** opens Google Maps with the saved stop destination. | Courier maps also use OpenStreetMap tiles; the current-job directions action opens external Google Maps directions. | Both map surfaces expose tile coordinates and source IP metadata to OpenStreetMap, which can reveal the displayed area. Google Maps receives the saved destination only when the rider explicitly opens external directions. The default Rider build does not read device location or send a live GPS feed or route history to Bagoo. |
| Waybill scanning | Android `mobile_scanner` accepts a real camera result and requires one matching parcel code. There is no typed or gallery substitute in the native scan action. | `WaybillCamera` uses browser `BarcodeDetector` and `getUserMedia`; when unavailable it offers typed entry or an external scanner. The form checks the entered code against the selected waybill. | Scanning is not app-exclusive. The native camera pipeline and stricter scan-only entry are implementation differences; neither proves physical camera acceptance. |
| Saved buyer instructions | The API maps the saved checkout note to `stop.instructions` only for a non-preview final-mile task whose current stop is the buyer. Home and Stop Mode show the exact supplied text or **No extra instructions provided.** | The reviewed Courier task/map surfaces show next-action guidance and the saved address; no display of the buyer's stored order note was found in their page/controller path. | Rider exposes the saved order note for its authorized buyer stop. It does not add structured entrance fields or change the destination, and the app never invents missing instructions. |
| Delivery proof | Camera/gallery selection, protected original proof for uncertain commands, and private proof viewing in retained Trips. The paid Wallet recipient/proof response was fixed on Bagoo review branch `9e58312`; its Rider client scenario passes locally. | Delivery and failed-attempt forms accept an image file. The Trips page shows recorded trip details and earnings, not the private proof viewer found in the app. A phone browser may offer camera or gallery through its file picker. | Both support proof submission. The app adds protected recovery and an in-app private-evidence view; do not claim that the website cannot take a photo. Wallet-specific retained evidence is only verified against the unmerged source branch, not current main or Azure. |
| Stop Mode and Parcel Finder | Dedicated Stop Mode includes session-only personal slot labels for an owned parcel. Labels clear on restart/sign-out and do not change server custody. | The reviewed Courier pages have a current-job/map panel; no matching personal parcel-slot labels were found. | Parcel Finder is the clearest extra rider-facing feature in the app. It is a personal organization aid, not dispatch, scanning, or custody evidence. |
| Trips and money | Trips separates recorded order status and retained evidence from Cash & remittance. The native cash screen sends pending-offer review/cancellation to the website. | Trips/Earnings combines trip history, released/pending earnings, shift cash status, earning entries, and a COD handover link; the cash page owns pending-offer review/cancellation. | Both cover trips and money, with different information grouped on screen. Some cash controls are browser-owned and reached by a handoff from the app. Show the actual returned status and ledger state; a delivery record alone is not a payout or hub receipt. |
| Messages and notifications | Assignment-bound messages and a Home notification inbox with bounded read behavior. | Courier Messages, a notification link/page, and the same courier role boundary. | Shared capabilities; source-level interaction safeguards differ. Live send/read acceptance remains open. |
| Company and handover | Company requests/offers and native missed-scan reporting/evidence/recovery entry points. | Company requests/offers in Profile and handover issue list/detail pages. | These are not app-only business workflows. Assignment acceptance, parcel custody, and authorized recovery remain server-owned. |
| Account and profile | Native onboarding, registration and sign-in; Profile/Settings plus first-party website handoffs for selected password, session-security and recovery flows. | Browser login, registration and pending-approval entry; responsive Profile pages for information, privacy/security/session review, assignment and vehicle records. | Both support courier account entry. Some account/security changes remain browser-owned; do not describe an app handoff as a native feature. |
| Retry and device behavior | Android camera lifecycle handling, background clearing of unsubmitted proof bytes with encrypted same-account recovery, and an encrypted account/API-scoped journal for uncertain commands and original proof bytes. | Browser forms use request tokens and page state; the reviewed pages do not show an equivalent protected native journal. | This is a resilience implementation difference, not full offline delivery. Rider does not provide in-app route following, server-side live tracking, or notification push in the default build. |

**Answer to “what does Rider Mobile have that the phone website does not?”**
**Session-only Parcel Finder labels inside Stop Mode** are a clear additional
rider-facing feature. Rider also displays the saved buyer delivery note on an
owned final-mile stop; the reviewed phone website shows its action guidance but
not that stored note. Other implementation differences include Android camera
lifecycle integration, protected recovery of uncertain writes and proof, and
the private proof viewer in retained Trips. Wallet-specific retained proof has
only passed against the unmerged Bagoo source branch; current main/deployed
compatibility remains open. Both clients use OpenStreetMap for map tiles and
open Google Maps for external directions; Rider's default build does not include
in-app road routing or GPS-follow navigation. The website also scans waybills
and accepts proof photos, and owns pending cash-offer cancellation and session
review; the app links to those browser workflows. Core delivery, trips, messaging,
notices, cash, company, and handover operations remain shared in the reviewed
source.

Neither Courier client is a Buyer or hub client. The rider records a recipient
handoff; the server returns the applicable order status. Newer flow-version
orders may complete automatically after verified handoff. The rider does not
issue a separate buyer-confirmation command, create hub receipts, assign
final-mile work, or mark hub cash receipt/platform reconciliation. The rider
can submit a cash handover; the owning hub and ledger remain authoritative.

Sources: Rider [workspace navigation](../../../lib/features/workspace/presentation/workspace_shell.dart),
[Home notifications and handover entry](../../../lib/features/home/presentation/home_dashboard.dart),
[Home selected-stop panel](../../../lib/features/home/presentation/home_task_panel.dart),
[Doorstep Guide](../../../lib/features/home/presentation/doorstep_guide.dart),
[Profile cash entry](../../../lib/features/settings/presentation/settings_page.dart),
[native onboarding](../../../lib/features/onboarding/presentation/onboarding_page.dart),
[native registration](../../../lib/features/auth/presentation/register_page.dart),
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
[Courier account routes](https://github.com/Auvryy/BagooPH/blob/f001d396b0e9ea6bfc2fdeb85ee24b66682b997e/routes/web.php),
[Trips/Earnings](https://github.com/Auvryy/BagooPH/blob/f001d396b0e9ea6bfc2fdeb85ee24b66682b997e/resources/js/Pages/Courier/Earnings.tsx),
[Messages](https://github.com/Auvryy/BagooPH/blob/f001d396b0e9ea6bfc2fdeb85ee24b66682b997e/resources/js/Pages/Courier/Messages.tsx),
[Profile](https://github.com/Auvryy/BagooPH/blob/f001d396b0e9ea6bfc2fdeb85ee24b66682b997e/resources/js/Pages/Courier/Profile.tsx),
[company requests](https://github.com/Auvryy/BagooPH/blob/f001d396b0e9ea6bfc2fdeb85ee24b66682b997e/resources/js/Components/CourierCompanyRequests.tsx),
[Rider task API](https://github.com/Auvryy/BagooPH/blob/f001d396b0e9ea6bfc2fdeb85ee24b66682b997e/docs/api/RIDER_OPERATIONS_API.md),
[Rider task response source](https://github.com/Auvryy/BagooPH/blob/f001d396b0e9ea6bfc2fdeb85ee24b66682b997e/app/Services/Courier/RiderTaskService.php),
[buyer checkout note composition](https://github.com/Auvryy/BagooPH/blob/f001d396b0e9ea6bfc2fdeb85ee24b66682b997e/app/Services/Orders/CheckoutOrderService.php),
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
> Rider adds session-only Parcel Finder labels and a Doorstep Guide that shows
> the authorized final-mile stop's exact saved buyer note, or clearly says
> when none was provided. It also adds Android camera and lifecycle integration,
> protected recovery of uncertain submissions, and private proof viewing in
> Trips. Wallet-specific retained proof has only passed against an unmerged
> Bagoo review branch, so deployed Wallet compatibility remains open.
> Both clients use OpenStreetMap tiles and send the saved stop to Google Maps
> only when external directions are opened. Rider's default build has no in-app
> road routing or GPS-follow navigation. PC checks are recorded. Release
> signing, deployed cross-role acceptance, and physical Android acceptance are
> still pending.

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
   details into one screen. Its Doorstep Guide shows the exact saved buyer note
   for an owned final-mile stop, or says when no saved note is present; it
   never invents a landmark. Parcel Finder adds a personal
   compartment label that clears with the app session and never changes server
   custody. Both Rider map renderers request OpenStreetMap tiles for the
   displayed area. Tile
   coordinates and source IP address can reveal the approximate area to the
   provider. The default road-routing provider is unavailable, so there is no
   in-app GPS follow or rerouting. When the rider explicitly opens External
   directions, Google Maps receives the saved stop address or coordinates. The
   Android client also uses the native scanner lifecycle and preserves the
   exact pending command for same-key reconciliation; original proof bytes are
   encrypted separately. An unsubmitted photo draft is removed from memory on
   background and restored only from its encrypted, account-scoped copy on
   resume before the 24-hour cutoff. Explicit sign-out and invalid-session
   paths remove that draft while preserving command proof. An auth transition
   that changes account identity, approval or operations API version also purges
   the draft; a secure marker blocks later recovery and retries cleanup after a
   storage failure. Whole-app private-state cleanup and owner policy acceptance
   remain open. Rider does not claim full offline delivery. The local journal can
   retain private action-body fields, and its long-term cleanup policy remains
   open.
4. **Relationship to web — 45 seconds.** Courier web already includes queues,
   maps, camera scanning, proof upload, Trips/Earnings, Messages, notifications,
   cash handovers, company requests, and handover issues. Both clients use
   OpenStreetMap tiles and open external directions in Google Maps. Core courier
   operations remain shared. In the reviewed Courier pages, the saved buyer
   order note is not shown; Rider displays it for its authorized stop. These
   checks do not measure delivery speed, accuracy, or user satisfaction; claim
   gains only if a separate field study supports them.
5. **Evidence and limits — 60 seconds.** The latest full serial Flutter suite
   passed **715 tests, 8 skipped, zero failures** in 5m14s at Rider branch
   commit `f0de3a2`, including current runtime code `daacf85` and the Doorstep
   Guide tests. The preceding 713-test full run includes the account-access
   photo cleanup now published as `961d8b8`. The
   separate headless Wallet client scenario passed
   **1/1** against the unmerged Bagoo review branch `9e58312` with an in-memory
   storage adapter; it does not verify the deployed API or Android platform
   storage. The full suite used one worker. No
   phone, ADB, emulator, install, or app window was used.
   Focused photo-recovery and parcel-outcome suites passed **19/19** before the
   November 2 background-memory follow-up. Its final serial run passed **41/41**
   across photo recovery, parcel outcomes and parcel workflows; `flutter analyze
   --no-pub` reported no issues in 6.4s. The expanded serial **45/45** check
   includes approval-loss cleanup. These remain simulated PC checks, not
   physical Android acceptance. At Rider code commit `daacf85`, the focused
   Home and Stop Mode tests passed **46/46** and analysis was clean. The current
   arm64 debug APK was built from that commit and passed PC archive,
   package/SDK, ARM64-engine, manifest and APK v2 signature checks. The profile
   APK remains the earlier build from `ba7823a`. Exact hashes are in
   [Android release evidence](../../ANDROID_RELEASE.md). Neither was installed;
   both use the scaffold ID and Android Debug signing.
   Their build config uses the default deployed HTTPS API and enables only the
   HDB-05 accepted duty/pickup-claim writes; parcel, cash and other write gates
   remain false. The same-config fake-server activation test passed **2/2**
   without network requests; this is configuration evidence, not a live
   transaction check.
   An unauthenticated PC GET to Rider Home returned 401 JSON with private/no-cache
   headers and no redirect; no credentials or command writes were sent.
   A separate headless Rider client scenario passed against the pinned Bagoo kernel,
   including lost-response recovery, paid COD
   completion, cash separation, retained private proof and failed-return /
   reassignment. Focused evidence also includes 42 command/workflow/outcome
   tests at `3839de6`, 20 proof-recovery/Trips tests at `cbd6b21`, 20 Parcel
   Finder tests at `d42c948`, and six map-disclosure checks at
   `9d7e8cf`/`039d40d`. The APKs do not establish release signing, Azure
   deployment, cross-role production behavior, or physical Android
   camera/lifecycle acceptance. See
   [current APK evidence](../../ANDROID_RELEASE.md).

### Likely questions

- **What does the app add beyond the phone website?** Rider adds session-only
  Parcel Finder labels in Stop Mode and displays the exact saved buyer note for
  an authorized final-mile stop, including an explicit missing-note state. The
  reviewed Courier pages did not show that stored note. Other implementation
  differences include native camera lifecycle handling, protected recovery for
  uncertain submissions, and private proof viewing in Trips. Both clients
  support waybill scanning and proof upload. Wallet-specific retained proof
  still needs the unmerged Bagoo fix deployed and accepted.
- **Does Rider provide in-app navigation?** Not in the default build. The active
  map shows a saved stop or sample path, but `roadRoutingProvider` is
  `UnavailableRoadRouting`; there is no GPS follow or rerouting session.
- **What location or destination data leaves the app?** The default Android APK
  does not declare location or foreground-service permissions, and its Home
  location controller is not connected to the Home surface. The default app
  therefore does not read device location. OpenStreetMap tile requests still
  include the displayed area’s tile coordinates and source IP, which can reveal
  its approximate location to the tile provider. If the rider explicitly opens
  External directions, Google Maps receives the saved stop address or
  coordinates. Rider sends no live GPS feed or traveled-route history to Bagoo.
  The default `roadRoutingProvider` is `UnavailableRoadRouting`, so the
  background-capable navigation code cannot be started through the current
  interface. A future route provider would require an explicit manifest and
  permission review plus physical Android acceptance. The public OSM tile
  service is best-effort without an SLA, so
  this is a bounded demo provider, not a production availability promise; its
  official policy and the current provider follow-up are recorded in the
  [street-map plan](../rider-street-map/README.md).
- **Does delivery still work without internet?** No full offline delivery is
  claimed. One scoped journal retains an uncertain command's exact body and
  proof reference so the app can check or retry the same operation when
  connectivity returns. The original proof bytes are stored separately. This
  is recovery for one unresolved command, not an offline work queue.
- **What if Android stops the app while a proof photo is being selected?** The
  native picker path records the exact API/account/task/action/version context.
  It can recover one matching photo for up to 24 hours into encrypted app-owned
  storage. The restored image stays a draft and never submits an outcome by
  itself. Rider also drops the recovered image from memory while backgrounded
  and reloads the encrypted copy on resume if it is still fresh. The November 2
  expanded PC checks recorded below cover simulated picker/storage, background
  and resume, expiry cleanup and late picker rejection; actual Android
  kill/resume acceptance remains open.
- **What happens to an uncertain request after sign-out or an account change?**
  The complete `CommandIntent`, including its action body, is saved through
  Flutter Secure Storage under API-origin, account and feature-scope keys; it
  does not contain a bearer token. The original proof bytes are in a separate
  AES-GCM protected file. The unresolved record survives sign-out for that
  account and is checked before a new command can replace it. An unchanged
  retry is allowed for seven days; after that the retry stops, but the unknown
  record is retained and still blocks new commands in that scope. This retention
  behavior is implemented, while its owner-approved cleanup policy remains
  open in M01.06/M16.02.
- **What private drafts clear when the app backgrounds?** Message history and
  inbox data clear, but unsent message text remains in the in-memory chat
  controller. An unsubmitted parcel photo is cleared from memory and reloaded
  from its encrypted account/API-scoped copy on resume only while under 24
  hours. If it expires while backgrounded or stopped, cleanup occurs on resume
  or the next same-account restore. Explicit sign-out and invalid-session paths
  delete its encrypted draft and picker marker; an unresolved command's
  separately retained proof survives for reconciliation. Approval/restriction
  transitions clear the unsubmitted photo when the auth provider publishes the
  changed account state. The Trips proof viewer clears on background. See the
  [source audit](PRIVATE_DATA_LIFECYCLE.md); message-draft policy, whole-app
  cleanup and real Android lifecycle acceptance remain open. The task queue and
  selected stop also remain in memory; Stop Mode keeps the stop details rendered
  while inactive, disables its actions and revalidates on resume. Android
  recent-app snapshot behavior for those details has not been verified.
- **Does the rider confirm that the buyer received the parcel?** The rider
  records the handoff. The backend returns the applicable status; newer
  flow-version orders may complete automatically. There is no separate
  Rider-issued buyer-confirmation command.
- **How do you know the app improves delivery performance?** The current
  evidence verifies client behavior and selected isolated API flows. It does
  not measure delivery speed, accuracy, or satisfaction; those gains require a
  separate field study.
- **Is it ready for a live Android defense demo?** The available
  arm64-targeted debug APK was built and verified on the PC from Rider commit
  `daacf85`; the profile APK is from `ba7823a`. Neither has been installed.
  Both use the scaffold application ID and debug signing. Approved release
  identity/signing, deployed cross-role acceptance, and physical Android
  acceptance remain open, so a live-phone demo is not yet accepted.

Present device-dependent steps only after the approved account, isolated owned
resources, deployment, and physical Android checks in the acceptance table are
complete. Until then, describe them as implemented source behavior with PC
evidence, not as an accepted live phone demonstration.

## Current PC evidence and open gates

- The latest full serial Flutter suite passed **715 tests, 8 skipped, zero
  failures** in 5m14s at Rider branch commit `f0de3a2`, with current runtime
  code `daacf85` and the Doorstep Guide tests. The preceding 713-test run at
  `968e18f` contains the account-access photo cleanup follow-up. The headless
  Wallet client scenario passed
  **1/1** against Bagoo `9e58312` with an in-memory storage adapter.
  Focused photo recovery and parcel outcomes passed **19/19** before the
  lifecycle follow-up; the expanded relevant suite passed **45/45** afterward.
  `flutter analyze --no-pub` found no issues in 6.4s. The suite and Wallet
  scenario are PC-only checks; the latter does not test Android platform
  storage. Android picker process-death, Azure deployment, release
  signing, and production cross-role acceptance remain open.
- At Rider code commit `daacf85`, the focused Home and Stop Mode widget tests
  passed **46/46**, and `flutter analyze --no-pub` found no issues. An arm64
  debug APK was built from that same source. It is 176,228,861 bytes, with
  SHA-256 `215a1275cc6e4b83a7dce8a39e3d5a493cdecfd9391f91d1114e61af139e6d61`.
  ZIP integrity, package/SDK metadata, ARM64 Flutter engine, manifest
  permissions and the single-signer APK v2 signature passed PC checks. It was
  not installed; see [Android release evidence](../../ANDROID_RELEASE.md).
- **November 2 photo lifecycle follow-up:** the focused photo recovery, parcel
  outcome and parcel workflow suites passed **41/41** serially. Coverage now
  includes immediate form selection clearing on background, encrypted-draft
  recovery on resume, stale in-flight restore protection, expiry cleanup and
  sign-out deletion that preserves command proof, rejects a late picker result
  and removes proof saved by an in-flight selection. `flutter analyze --no-pub`
  found no issues in 6.4s. Simulated
  storage/picker checks do not establish physical Android lifecycle or OS
  storage behavior. The expanded serial **45/45** PC pass includes
  approved-to-holding cleanup through the workspace provider and marker-backed
  retry after a proof deletion failure. M16.02 owner policy acceptance, other
  private-state cleanup and physical Android behavior remain open.
  The subsequent complete serial suite passed **713 tests, 8 skipped, zero
  failures** in 4m37s on the working tree based at `968e18f`.
  The tested account-access cleanup source is now pushed as `961d8b8`.
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
- The focused photo-recovery suite now passes **8/8**, including active expiry
  cleanup with a simulated clock and preservation of unresolved command proof.
  Its picker and storage are simulated; it does not establish physical Android
  lifecycle behavior. The earlier 7/7 run at `f17309c` is historical.
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
- At the November 2 GitHub ref check before this documentation refresh, Rider
  `main` was `4367331c51ea1dc98b7b512669242a1d3283d523`; the defense branch
  was `d83ffe56c1935c6553462896a8ebca340cf21902`, 85 commits ahead and 0 behind.
  Its tested runtime remains `daacf85`; the commits through that snapshot after
  the runtime change update documentation only. Bagoo `main` is
  `f001d396b0e9ea6bfc2fdeb85ee24b66682b997e`, and its Wallet/handover source
  branch is `9e58312d130809eb8cd878189b729f1f702291d8`, 2 commits ahead. Those
  fixes remain unmerged and do not establish deployment or live acceptance.
- The latest arm64 profile preview was built from Rider commit `ba7823a`, which
  changes only the Android manifest after the Dart source tested at `961d8b8`.
  It is 77,671,976 bytes, with SHA-256
  `f6334ab298f784444a5ae905372a274eb79e0df7f8d2a1280d7852bd90ac68a5`.
  Archive integrity, package/version/SDK metadata, arm64 engine contents and
  v2 Android Debug signing passed PC checks. It uses the scaffold package ID
  and was not installed. See [packaging evidence](../../ANDROID_RELEASE.md).
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

If an Android device is unavailable during the defense, Linux Device Preview
can show the PC layout. Its debug build passed, but it has not been launched in
this verification; it uses the FlutterMap fallback and is not Android renderer
or lifecycle evidence. Present the PC walkthrough and recorded evidence without
implying a live Android demonstration:

**Map preview limit:** Linux Device Preview uses the FlutterMap fallback so the
map stays inside the simulated phone frame. Android uses the bundled Leaflet
document in System WebView. The Linux preview supports layout/workflow review,
but it does not verify Android's map renderer or lifecycle. Local Leaflet runtime
checks cover the bundled document separately.

From the Rider repository root, launch the PC walkthrough only when you are
ready to open its window:

```sh
flutter run -d linux --debug --dart-define=DEVICE_PREVIEW=true --dart-define-from-file=.env.rider.json
```

1. Give the four-minute explanation above and show the source-backed
   [app-versus-website comparison](#rider-app-versus-phone-sized-courier-website).
   Make clear that the website already supports scanning and proof upload;
   Rider adds session-only Parcel Finder labels and the saved-note Doorstep
   Guide for an authorized final-mile stop. Identify any running Linux frame as
   a desktop preview, not Android hardware behavior.
2. Show the PC evidence above with revisions attached: the latest full suite
   passed 715 tests with 8 skips at Rider commit `f0de3a2`, with runtime code
   `daacf85`;
   the headless Wallet client scenario passed 1/1 against Bagoo `9e58312` with
   an in-memory storage adapter;
   the arm64 debug APK from `daacf85` and the earlier profile APK from `ba7823a`
   are PC-verified, debug-signed, and uninstalled. They do not establish
   hardware behavior.
3. If asked to demonstrate an operational transaction, explain that Azure and
   cross-role acceptance are separate open gates. Do not substitute sample data
   or imply that a PC test changed a live assignment, order, proof or cash record.
4. Close with the acceptance table below. State that physical Android camera,
   lifecycle, permissions and layout checks remain deferred.

Suggested wording: “Today I can show the implemented Rider workflow and its PC
verification. Physical Android and deployed cross-role acceptance are still
pending, so I am not presenting this as an accepted live-phone demo.”

Use this status view with the broader [acceptance matrix](../../VERIFICATION_AND_READINESS.md#acceptance-matrix), which defines the positive and adverse cases. This table does not mark its external, release or physical-device gates complete.

| Check | Verified evidence to present | Acceptance still open |
|---|---|---|
| Account access | Dated native Azure account checks and a physical Android login/storage/restore/logout/revocation check are recorded in [account access evidence](../../AZURE_ACCOUNT_ACCESS.md). | No fresh phone check of the current defense artifact. Pending, restricted and expired-account transitions remain separately bounded by local checks. |
| Company | The headless Rider consumer scenario passed **1/1** against Bagoo `9e58312`, covering original-key replay, stale-offer rejection, exact placement consent and duty remaining off ([verification](VERIFICATION.md)). | Azure capability and live company/offer acceptance with owning-site readback. |
| Pickup | Controlled Azure duty/claim acceptance and the owning website's **20/20** post-check are recorded in [HDB-05 evidence](../home-dashboard-branch-plan/HDB-05-EVIDENCE.md). | Physical camera/scanner, origin-hub receipt, two-rider contention and later parcel operations. |
| Version-two COD | The isolated `parcel-headless` Rider-to-kernel scenario covers synthetic COD delivery, exact replay and private proof; the latest PC recheck also covers failed return ([parcel verification](../rider-orders-delivery-trips/VERIFICATION.md)). | Current deployed contract, authorized buyer/hub readbacks, real counted cash and physical scan/proof handling. |
| Paid Wallet | The native Wallet client scenario passed **1/1** against Bagoo source `9e58312`, including replay, original recipient and retained private proof ([workflow verification](VERIFICATION.md)). | Merge/deploy of the Bagoo fixes, fresh deployed capabilities and controlled owned-resource cross-role acceptance. |
| Failure/return | The isolated PC kernel scenario records one failed attempt, hub return, authorized retry and foreign-proof denial ([parcel verification](../rider-orders-delivery-trips/VERIFICATION.md)). | Deployed hub receipt/retry/RTS readbacks and physical Android proof/return handling. |
| Cash/shift | The in-memory native cash scenario verifies original-command replay, two owning-hub receipts, shortage handling and earnings separation ([cash verification](../rider-cash-remittance/VERIFICATION.md)). | Current Azure migrations/capability, authorized live rider/hub receipts and physical financial-input/lifecycle checks. |
| Messages/notices | Controller/widget and isolated-kernel behavior is recorded in [Messages verification](../rider-assignment-messages/VERIFICATION.md); the latest broad PC regression is summarized above. | Deployed send/read acceptance, live phase boundaries and later-arrival-unread behavior. |
| Security/recovery | Fixed first-party recovery links and simulated private-draft cleanup are recorded in [workflow verification](VERIFICATION.md) and the [private-data audit](PRIVATE_DATA_LIFECYCLE.md). | Owner decisions for retained private data; deployed restricted-custody recovery; Android picker/process-death behavior. Task/stop details also remain visible while inactive, and Android recent-app snapshot behavior is unverified. |
| Phone lifecycle | PC simulations cover picker recovery, background clearing and expiry; the [private-data audit](PRIVATE_DATA_LIFECYCLE.md) lists what remains source-only. | Actual camera permission/cancel/retry, process kill/resume, account switch, keyboard/Back, task-detail redaction and app-switcher snapshot review. No current phone test was performed. |
| Release identity | The arm64 debug APK and profile preview have PC archive/signature checks in [Android release evidence](../../ANDROID_RELEASE.md). | Approved application ID, protected release key, reproducible signed artifact, install/launch and artifact/source identity check. Debug APKs are not distributable releases. |
| Deployment/cross-role | HDB-05 duty/claim is the only recorded controlled operational deployment acceptance; current Bagoo `main` and Wallet source refs are pinned above. | Confirm the deployed source/migrations for each operation and complete authorized rider, buyer, hub and cash readbacks. Source tests and `401` checks do not satisfy this gate. |
| Evidence freeze | The Rider source/test basis, pre-refresh branch ancestry snapshot, Bagoo `main` and unmerged Wallet source refs are recorded above; APK hashes and build limits are in [Android release evidence](../../ANDROID_RELEASE.md). | Freeze the exact signed artifact, tested source and deployed revision, preserve selected test-resource results, then rehearse before November 20. |

Use the existing narrow acceptance procedures for each action family. No build
flag is evidence that these checks passed. No notification push, live tracking,
turn-by-turn routing or full offline delivery is claimed by this delivery.
