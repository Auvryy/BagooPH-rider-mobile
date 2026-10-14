# Home review, evidence and bug inventory

This is the baseline review. The subsequent [HDB-01 implementation](HDB-01-EVIDENCE.md)
owns the fixes for BUG-H01/BUG-H02 and the user's Settings touch/navigation
correction; remaining findings retain their later branch ownership.

## Reviewed source and limits

Mobile source is `e04a2536987eaf31cf1e6760207dba1da80d9258` on clean `main` before
this documentation branch. The Home changes were already merged through PR 16.
No runtime source is modified by this review.

Initial backend reference was `0571f75d10cac0dc9f7da9875e4d801fdc941bdc`. At first inspection
there were 34 changed/untracked paths from another developer, principally
registration/account validation, profile UI, identity rules and tests. In
particular, `RiderAuthController`, `User`, `Shop`, the registration fields and
courier Profile had work in progress. That work is not treated as committed,
deployed or accepted by this mobile review. Nothing in the backend was edited,
staged, reset, switched, tested or deployed by this mobile review.

During the review the other developer advanced their checkout to
`10619cea9fac27a642533e401180f6a618f72158` on
`fix/registration-contact-uniqueness`. The follow-up read had 59 changed/untracked
paths. The checked native Home routes/contract/task/operations services retained
their original fingerprints. Courier Deliveries changed its photo hint/accept list
to JPEG/PNG/WebP. Account password policy changed to 8–128 and registration sex
requirements had a source/document mismatch; see [account compatibility](ACCOUNT_COMPATIBILITY.md).
These external changes were read and preserved, not rolled back. The snapshot
does not certify their publication, deployment or tests.

The final source check then observed clean backend main at
`b91f13a57c7fedbd0252b0d98eeefe834b160aee` (the registration-contact merge).
Home/API fingerprints still matched the initial review. The account source/docs
sex requirement discrepancy remained present. This records the owner's advancing
checkout; it does not claim a fresh Azure deployment or a mobile account repair.

The native operations contract is still OpenAPI `1.0.0`, 25 methods/24 paths,
SHA-256 `8b09acf2e933441ee766820c94f65eafe1240c6c343b659e89487c6ab1e507eb`.
This is source evidence. October 9's older backend deployment failure and the
later mobile successful Home/empty-queue reads are dated observations; neither
is a fresh October 13 audit of Azure, assigned test parcels or physical GPS.

## Home surface inventory

| Surface/state | What exists | Review outcome and next work |
|---|---|---|
| Account entry and holding | Approved accounts enter the workspace; pending/rejected accounts keep holding/account flows | Preserve approval/access handling and Settings. Recheck the website's account WIP before live acceptance |
| Workspace header and bottom/side navigation | Tasks, Trips, Messages and Profile; global navigation Stop/refresh banner; Home reserves bottom-nav space | Keep four primary destinations. Home map is mounted inside an IndexedStack; hidden-view request/paint behavior needs deliberate review in HDB-02 |
| Duty, company/hub and eligibility | Compact hub/barangay/duty control, actual capacity/denials and pending request controls | Add actual company and checked time without repeating large metric cards. Disabled writes are an acceptance gate, not proof of a broken switch |
| Available pickups | Seller-only previews, returned counts, task selection and claim control in detail | Claims use existing native APIs. No buyer/payment/phone leak, preview GPS or collection-by-claim |
| My pickups | Owned rows, selected stop and origin-hub instruction after collection | Real scanner/collection remains unconnected. Hub intake is hub-owned; plan HDB-07 |
| Assigned delivery | Owned current hub/buyer stop, exact COD and next instruction | Real departure/delivery/failure remains unconnected; plan HDB-08–10 |
| Queue choices and search | Full labels/counts, local search over loaded tracking/stop/address rows, pagination button | Explain loaded search scope and unfiltered server counts. Preserve explicit queue choice and a selected stop's relationship to the filter |
| Selected-stop summary | Name/address, next instruction, COD, missing-pin explanation, View details and Show stop | Add full parcel identifier and a clearer Work this stop entry. Do not infer possession from assignment |
| Parcel detail sheet (baseline) | Revalidated owned detail, preview claim, buyer notes, navigation controls and pending-command status | October 14 HDB-04 replaces live detail with a normal full-page Stop Mode, fresh contact/directions and lifecycle guards; [scoped evidence](HDB-04-EVIDENCE.md). Physical actions remain separate |
| Map and attribution | Valid pins, stable tile provider, card/pin selection, Recenter, route/queue fit and inline credits | No draggable sheet remains. Keep bounded map, readable notices, visible credits and address fallback; prove hidden-map/camera behavior |
| Linux origin/profile controls | Explicit manual origin; registered vehicle wins over a chosen fallback profile | This is layout/network/manual-route evidence, not Android GPS. Profile picker clarity can improve without changing correct precedence |
| Android Navigate/Stop | Contextual location/notification preparation, foreground service, persistent controller and authorization timers | BUG-H04 handles normal stream completion poorly. Permission, screen-off, reassignment and force-stop acceptance still needs a phone |
| Loading/refresh/empty/unavailable/failure | FeatureData retains old data during refresh/failure; distinct unavailable and empty UI | BUG-H01 leaves an old read error latched. Add checked/stale context and useful recovery without hiding unresolved writes |
| Refresh, fresh hidden task and late replies | Generation guards, direct-open hidden-task removal, explicit queue choice preservation | BUG-H02 is the inconsistent refresh-detail 404 path |
| Pending/replayed/expired work | Account/API-scoped original UUID retained; Check/Retry original request controls | Current journal supports duty/claim only. HDB-06 extends typed variants and protected original-file policy before later writes |
| Trips/Messages/Profile return to Home | Existing pages and account-safe shell; live Trips/messages still unavailable | Home shortcuts must reflect real connected capabilities. Trips/message/cash adapters have their own HDB/OPS branches |
| Small/large-text/keyboard/window resize | Normal page slivers on phones, side panel in wide windows, short-view fallback, search retained | Existing geometry/large-text tests pass. Actual phone touch, scrolling feel and performance remain unverified |

The review covers Home's entry, queues, summary/detail, map, navigation controls,
recovery states and surrounding shell behavior. Trips/Messages/Profile are reviewed
for Home integration and access boundaries; this is not a new full Settings audit.

## Confirmed baseline defects

Each finding was reproduced against unchanged mobile source in an ignored audit
probe, with synthetic actors/tasks and no network/provider/GPS calls. The first
repair branch must convert the relevant case into a meaningful maintained
regression that expects corrected behavior.

| ID / priority | Reproduction and observed result | Source and owner |
|---|---|---|
| BUG-H01 / P2 | Load Home, fail a later Home read with a recoverable 500, then successfully refresh. Home becomes ready but workFailure still contains the old error, which WorkSummary displays | WorkspaceController.refreshHome/_workError and WorkSummary; HDB-01 |
| BUG-H02 / P1 | Select an owned task and start a synthetic route. Refresh gets a list row, then selected detail returns 404 because access changed between requests. Selection clears, but the cached row/pin remains, unavailableTaskId is unset and navigation stays active until another authorization path handles it | WorkspaceController.refreshTasks differs from openTask; HomeDashboard._queueCamera; HDB-01 |
| BUG-H03 / P2 | Baseline details rendered literal out_for_delivery rather than the friendly Home row label | Fixed by HDB-03 shared display formatting, merged in PR 20; [evidence](HDB-03-EVIDENCE.md) |
| BUG-H04 / P1 | Start navigation through a fake valid location adapter, then close its stream normally without an error. Navigation remains active | NavigationController.start registers data/error handlers without a completion handler; HDB-02 |
| BUG-H05 / P2 | Registration permits Sedan / Van, but forVehicle returns null for that value and a manual route without a fallback choice fails as unrecognized | RegisterPage, backend ApplicationValidationService.VEHICLES and NavigationProfile.forVehicle; HDB-02 |

BUG-H02 is a legitimate list/detail race, not an assertion that the server returns
foreign data. Fix known local invalidation immediately while retaining independent
authorization refresh. BUG-H04 proves the controller's response to stream closure;
it does not claim a specific physical Android device has exhibited that closure.

## Improvements and concerns, not proven new defects

- The map is shown even for an empty or entirely unlocated queue. It can push the
  task controls below the first view and spend tile requests without a current
  target. Improve useful density/loading deliberately while preserving the chosen
  map-first direction; do not call the overview a rider location.
- Map notes can compete with the bounded map at large text or multiple failures.
  Check their visible geometry and move lengthy explanations into normal page
  content rather than declaring an unobserved overflow crash.
- Paused-navigation feedback needs coverage when Home/the map is hidden. The
  global banner currently renders only active/starting states; test a visible
  revalidation explanation for a paused state in HDB-02 rather than assuming the
  message inside a map/detail view covers every screen.
- Local search and server queue totals have different scopes. The UI needs an
  explicit loaded-row explanation or a separately selected server search contract.
- Existing selected-stop summary lacks a full identifier, copy/contact controls
  and an obvious focused working view. This is missing presentation, not absent
  server assignment authority.
- Native failure_policy is present in the contract but the current Home task DTO
  does not consume the full policy. It belongs to the failure integration branch,
  not a fabricated default retry/attempt control now.
- Company, observed_at and capacity are available for a more useful overview.
  Native Home does not return completed-today, full activity-chart or unread-chat
  aggregate data. Browser dashboard fields do not establish a native API field.

## Existing behavior verified or preserved

Direct-open 404 removes cached task/pin and stops the route; late detail/account
results are guarded; fresh missing coordinates remove the selected pin; unknown
stage labels do not grant actions; off-duty owned work and explicit queue choice
are preserved; panning disables follow until Recenter. Registered vehicle mapping
takes precedence over the optional chosen fallback. Provider errors clear on a
later successful request. Longitude/latitude conversion, route failure, quota,
good-fix checks and rerouting/cancellation have existing tests.

These facts prevent us from planning a repair for behavior already implemented.
They do not make the four missing cases or physical-device gates disappear.

## Website findings that inform the plan

- CourierDashboard supplies three work metrics plus browser-only delivered-today
  and a chart explicitly limited to the latest ten delivery records at the current
  hub. Do not copy those into native Home as complete analytics.
- CourierCurrentJob shows identifier, checked tracking context, conceptual legs,
  stage/instruction, relevant contact actions and a bounded map. Transfer useful
  information hierarchy, not its CSS, renderer or an unsupported payload shape.
- Native RiderTaskService exposes only the current stop; coordinates currently
  appear only for owned buyer stops. Browser hubPayload and LogisticsHub already
  have saved hub coordinates, while native hub stops still return null.
- Native delivery is COD-only. Release, restricted recovery and earnings are
  disabled. Buyer completion, hub intake/retry and cash receipt remain separate.
- Owned seller contact mapping needs API-owner verification: native source reads
  pickup_contact_phone, but inspected model/schema/browser payload use pickup_phone.
  The client must keep a missing-contact fallback; no live response was checked.
- Existing native APIs already cover the five OPS batches. Most pending mobile
  work is consumption/acceptance; genuine API requests have a separate checklist.

## Evidence and source register

On October 13, 43 related existing tests passed in home_dashboard,
home_queue_priority, workspace_controller, navigation and workspace_pages suites.
Five additional isolated probes passed by asserting the five defects above.
No production login, live operational mutation, provider request, new APK build,
backend test/database operation or physical-device review occurred here.

Primary mobile files: HomeDashboard, HomeTaskPanel, WorkSummary, TasksPage,
WorkspaceController, RiderWorkspaceShell, FeatureData/FeatureStateView,
OperationsRepository/DTOs/journal, NavigationController/Controls/providers,
location/route/Geoapify adapters and the five test suites above. AccountGate/HomePage
and existing account/Settings providers establish the surrounding access boundary.

Primary backend files: routes/api.php; RiderTaskService, RiderAccountService,
RiderCommandService; RiderParcelController; CourierDeliveryController;
CourierDashboard, CourierCurrentJob, CourierJobMap, CourierDutyControl,
CourierLayout and Courier Deliveries; LogisticsHub/LogisticsFleet; RiderSettingsService;
native OpenAPI/contract/examples; RIDER_UI_DESIGN, COURIER_FLOW,
ORDER_TRACKING_CONSISTENCY, CORE_FLOW_ROADMAP and the normative system flow docs.

Read the [source authority](../../SOURCES.md) and current owner contracts on every
activation. The website's dirty account work, older operational planning snapshots,
source tests and real Azure acceptance are different evidence categories.
