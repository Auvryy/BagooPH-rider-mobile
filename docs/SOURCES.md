# Sources, authority and synchronization

## Reviewed source snapshot

Reviewed October 5, 2026 from the local Bagoo web checkout at
`f24704f0a74162369687b8bfce976775cd58208f`. No web files were edited for this task.
Public links below navigate the main branch of `Auvryy/BagooPH`; this review does
not establish that its local commit is already published or that remote main
will keep the same content. Re-read current authoritative sources at each API
slice and record changed rules before implementation.

The October 5 major-task planning follow-up reviewed courier flow/design, current
Rider screen/controller behavior, API routes/token indicators and backend phase
dependencies at `88ed1871e39755ae09ee233112351e42472fda30`. A read-only authenticated
remote-main check matched that checkout. The observations in
[TASK_TRACKING.md](TASK_TRACKING.md) and [api/INTEGRATION_PLAN.md](api/INTEGRATION_PLAN.md)
are scoped snapshots, not a new full backend audit or deployment verification.
The original normative-source review above remains dated to its earlier commit.
GitHub links may require repository access; the authorized checkout is available
for source review when unauthenticated pages are unavailable.

The detailed-subtask review on October 5 observed the buyer-access branch at
`cbb941c284cd83f2d41ae3cb13db6a583a97ee06` with a roadmap edit in progress.
The other developer subsequently advanced the checkout to clean local `main`
at `16b502c5381938e9a9cfb7300f176b3311511713`. No web edits, commits, branch changes
or resets were performed by this Rider task. The newer roadmap includes B05
buyer holding and narrow owned-existing-order receipt behavior; delivery and
whole-flow cards include that authorization boundary. The inspected API routes
still expose public tracking only. This is source evidence, without a fresh
remote-main comparison, deployment check or rerun of the backend's reported tests.
Refresh it at each future slice rather than treating this as a live status list.

This repo adapts rider responsibilities and presentation instead of copying the
entire web documentation directory. Full copies would create competing state
models and duplicate a changing implementation audit. Historical source material
is useful context, never permission for a weaker mobile shortcut.

## October 6 dispatch and selected-feature review

The selected [frontend direction](FEATURE_DIRECTION.md) reviewed the local web
checkout at `3db99d84604d218dbc151ea71cb3814adea95a59`. The shared checkout had
unrelated in-progress work; this Rider review changed none of it. This is a
scoped source observation, not publication, deployment or new runtime-test
acceptance. The backend roadmap still owns implementation/remediation status.

| Reviewed source | Observation relevant to the mobile plan |
|---|---|
| `docs/COURIER_FLOW.md` | Logistics placement is separate; seller pickups are rider-claimed, while the destination hub assigns final-mile work to an eligible barangay rider |
| `app/Http/Controllers/Courier/CourierDeliveryController.php` and `app/Services/Courier/CourierOperationsService.php` | Available pickups and atomic claims check company/origin hub, readiness, duty and capacity; no seller-barangay check was found on that path |
| `app/Models/Delivery.php` | Current active-pickup maximum is five; clients should receive capacity rather than hardcode it |
| `app/Services/Logistics/OrderStateMachineService.php` | Final-mile assignment checks company/destination hub and rejects a configured barangay mismatch when destination barangay is present; a missing rider barangay does not make that conditional comparison fail |
| `app/Services/Logistics/LogisticsEligibilityService.php` and `resources/js/Pages/Hub/Deliveries.tsx` | Hub candidates exclude active courier work; the UI includes matching or unconfigured barangay riders; new final-mile assignment is not an accepted multi-parcel run |
| `docs/CORE_FLOW_VALIDATION_AND_EDGE_CASES.md` | Required company/hub/barangay scope must be respected; pickup-area policy and missing coverage semantics need agreement rather than a claim of universal strict barangay enforcement |

The selected three features change presentation/planning only. Any stricter
pickup-area rule, mandatory exact final-mile coverage or delivery batching
needs an explicit owning-backend decision and tests before the client relies
on it. No new endpoint or contract revision was accepted by this review.

## October 6 complete frontend design review

The [complete design specification](DESIGN_SPEC.md) reviewed the Rider project's
selected features and the relevant website sources at local revision
`0e4839e773bdcf726933a22efd69c4400018d658`, with another maintainer's roadmap work
in progress. It changed no website files or backend rules. The separate
[design source register](design/SOURCE_REGISTER.md) records current primary
guidance, historic research and access limits under neutral labels. Original
reference URLs remain intact for verification.

The design catalog covers all 16 mobile major areas and all 40 earlier ideas;
counts and optional/future labels do not establish native routes or accepted
APIs. Static visual examples and calculated contrast remain documentation
proof, without deployed, prototype-interaction or physical-device acceptance.

## October 7 deployed account review

The account slice reviewed backend main `0132562`, including
`docs/RIDER_ACCOUNT_API.md`, `RiderAccountService`, native auth routes,
registration services and website login/domain middleware. The web maintainer
reported deploying this revision to Azure. Live HTTPS checks establish route
availability and native account behavior, without independently reading the
VM's Git checkout. The Rider website is on the courier subdomain; root-host
website login enforces the buyer role. The native API remains under `/api/v1`
on the root host.

[AZURE_ACCOUNT_ACCESS.md](AZURE_ACCOUNT_ACCESS.md) records exact local, live
Linux and physical Android checks, their initial failures and remaining gaps.
Only Rider files were changed for this integration task. This accepted account
contract does not accept the planned parcel-operation APIs or complete the
broader authentication/operational backlog.

## Web authority map

### October 8 Rider pages source review

The Flutter Home/Trips/Messages/Settings branch reviewed backend main `fe86abf`,
its courier layout/sidebar, Deliveries, Earnings (the Trips web route), Messages,
Profile and courier controller/services. The accepted web message phase values
are `pickup` and `final_mile`; recipient/read permission is server-owned. The
current native API routes remain account/registration only. Workspace presentation
models are not a new accepted wire contract; proposals and remaining ownership
are recorded in [api/WORKSPACE_HANDOFF.md](api/WORKSPACE_HANDOFF.md).

Another maintainer subsequently switched the shared web checkout to seller work.
This Rider slice did not switch, edit, commit or reset that repository. Flutter
uses the documented accent, blush canvas, eight-unit corners, bundled font and
native four-destination navigation with Settings nested under Profile.

| Source | Authority and use in this repo |
|---|---|
| [docs/README.md](https://github.com/Auvryy/BagooPH/blob/main/docs/README.md) | Documentation routing, realistic scope, November 20 backend target |
| [SYSTEM_FLOW_AND_SPECIFICATIONS.md](https://github.com/Auvryy/BagooPH/blob/main/docs/SYSTEM_FLOW_AND_SPECIFICATIONS.md) | Canonical commercial states, fixed roles, buyer-only completion, financial gates |
| [CORE_FLOW_VALIDATION_AND_EDGE_CASES.md](https://github.com/Auvryy/BagooPH/blob/main/docs/CORE_FLOW_VALIDATION_AND_EDGE_CASES.md) | Server validation, authorization, locks/idempotency, suspension/recovery, proof and cash rules |
| [SORTING_CENTER_LOGISTICS_FLOW.md](https://github.com/Auvryy/BagooPH/blob/main/docs/SORTING_CENTER_LOGISTICS_FLOW.md) | Physical custody, Mother Hubs/manifests, failed return/retry/RTS, counter self-pickup and COD movement |
| [COURIER_FLOW.md](https://github.com/Auvryy/BagooPH/blob/main/docs/COURIER_FLOW.md) | Pickup/final-mile phase duties and rider notifications |
| [ADMIN_FLOW.md](https://github.com/Auvryy/BagooPH/blob/main/docs/ADMIN_FLOW.md) | KYC versus placement, company/handler governance, restrictions and recovery authority |
| [STYLE_GUIDE.md](https://github.com/Auvryy/BagooPH/blob/main/docs/STYLE_GUIDE.md) | Brand, typeface, accessible presentation |
| [RIDER_UI_DESIGN.md](https://github.com/Auvryy/BagooPH/blob/main/docs/RIDER_UI_DESIGN.md) | Task hierarchy, relevant stop/directions, message/proof interactions |
| [AGENTS.md](https://github.com/Auvryy/BagooPH/blob/main/AGENTS.md) | Latest specific rider preferences: 8px corners, `#FFFAFB` canvas, subtle outlines/shadows; apply in native logical pixels |
| [CORE_FLOW_ROADMAP.md](https://github.com/Auvryy/BagooPH/blob/main/docs/CORE_FLOW_ROADMAP.md) | Sole changing backend implementation audit, accepted phase order and remaining gaps |
| [ARCHITECTURE.md](https://github.com/Auvryy/BagooPH/blob/main/docs/ARCHITECTURE.md) | Supporting context: Laravel/Inertia/React monolith, services, PostgreSQL/Docker |
| [VERIFICATION_DOCUMENT_SECURITY.md](https://github.com/Auvryy/BagooPH/blob/main/docs/VERIFICATION_DOCUMENT_SECURITY.md) | Existing private document protection and deployment/operator requirements |

Executable starting-point references include
[routes/api.php](https://github.com/Auvryy/BagooPH/blob/main/routes/api.php),
[composer.json](https://github.com/Auvryy/BagooPH/blob/main/composer.json),
[User.php](https://github.com/Auvryy/BagooPH/blob/main/app/Models/User.php), and
the services listed in [api/INTEGRATION_PLAN.md](api/INTEGRATION_PLAN.md).
Migrations/models define executable storage. Supporting schema drafts do not
prove API payloads, migration deployment or new ledger readiness.

## Conflict rule

1. Use the system specification for commercial status and actor ownership.
2. Use the validation contract for input, authorization, concurrency and failure safety.
3. Use the sorting-center contract for physical custody.
4. Use role documents for permitted rider presentation/actions.
5. Use the backend roadmap for implementation state and dependency order.

The later explicit rider radius/canvas preference supersedes older larger rider
cards in the design guide; it does not restyle other portals or change business
authority. Flutter presentation adapts web interaction intent without assuming
web CSS breakpoints, Leaflet components, or browser authentication transfer.

If backend code contradicts a normative contract, report it to its owner and
record the gap in that repo's roadmap. If a proposed mobile endpoint contradicts
a rule, amend the proposal before implementation. Do not create another source
of truth by editing the contract to match a bug or stale demo.

## Technical sources

Consulted official docs/package maintainer pages on October 5, 2026. These
support tool capabilities and general patterns; exact folder structure,
polling budgets and contract field choices are project recommendations.

| Primary reference | Use |
|---|---|
| [Flutter architecture recommendations](https://docs.flutter.dev/app-architecture/recommendations) | UI/data separation, repositories/views, conditional domain layer |
| [Flutter accessibility](https://docs.flutter.dev/ui/accessibility) | Screen-reader review, contrast, touch targets and large-text acceptance |
| [Flutter Android setup](https://docs.flutter.dev/platform-integration/android/setup) | Native tooling/device verification |
| [Android sdkmanager](https://developer.android.com/tools/sdkmanager) | SDK command-line tooling without requiring an IDE |
| [Riverpod](https://pub.dev/packages/flutter_riverpod) | Proposed asynchronous state/dependency tool |
| [Dio](https://pub.dev/packages/dio) | Proposed shared transport/uploads/interceptors |
| [go_router](https://pub.dev/packages/go_router) | Proposed route handling |
| [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) | Native token storage and Linux Secret Service requirements |
| [mobile_scanner](https://pub.dev/packages/mobile_scanner) | Camera scanning and unsupported Linux platform |
| [image_picker](https://pub.dev/packages/image_picker) | Android lost-data handling and desktop camera limits |
| [url_launcher](https://pub.dev/packages/url_launcher) | External navigation/browser/contact handling |
| [Laravel Sanctum](https://laravel.com/framework/docs/13.x/sanctum) | Native token versus first-party cookie auth, expiry/revocation |
| [Cloudflare Full (strict)](https://developers.cloudflare.com/ssl/origin-configuration/ssl-modes/full-strict/) | Validated origin TLS |
| [Cloudflare cache-rule settings](https://developers.cloudflare.com/cache/how-to/cache-rules/settings/) | Private API cache bypass planning |
| [Cloudflare challenge pages](https://developers.cloudflare.com/cloudflare-challenges/challenge-types/challenge-pages/) | Native API cannot solve an HTML interstitial |
| [OpenStreetMap tile policy](https://operations.osmfoundation.org/policies/tiles/) | Attribution/provider restrictions if embedded public tiles are selected |

No package version or policy is assumed permanent. Check primary docs at the
implementation task, pin tested resolutions, and record material constraints.
Live hosting, a signed Android release and hardware behavior were not audited
by this documentation source review.

## Synchronization checklist

For each feature: re-read the relevant current web rules/roadmap; agree the
backend contract/version; update the mobile flow/schema examples and acceptance
cases; verify both roles see the same result; record the actual checks and
remaining limits. Publish only reviewed public references and synthetic examples.
Local work-guide provisioning belongs outside GitHub documentation.

## October 8 implemented Settings source review

Backend local main was clean at `1dba047937b5f9c864112407586de4d1051f30db` during this scoped read. Reviewed
`docs/api/RIDER_SETTINGS_API.md`, `routes/api.php`, `RiderSettingsController`,
`RiderSettingsService`, `RiderAccountService`, `EnsureRiderAccountToken` and the
Settings feature-test source. The [backend contract](https://github.com/Auvryy/BagooPH/blob/1dba047937b5f9c864112407586de4d1051f30db/docs/api/RIDER_SETTINGS_API.md) is the authority
for this consumer; the former mobile proposal does not override it.

No website files, branch, database, migrations or tests were changed/executed.
Flutter checks use a synthetic contract example and its own test transport.
The user is preparing Azure deployment, so deployed Settings/version/migration
acceptance and real-account mutations remain outstanding. See
[the consumer contract](api/SETTINGS_HANDOFF.md) for the exact client scope.
