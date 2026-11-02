# Decisions and ideas to review

## Recommended baseline choices

| Choice | Evaluation | Implementation condition |
|---|---|---|
| One courier app for pickup and final mile | Good: matches the approved role/assignment model | Keep phase-specific permissions and data |
| Existing Laravel monolith plus `/api/v1` JSON | Good: reuses policies/transactions and existing hosting | Backend-authorized adapters and tests, not copied Inertia logic |
| Feature folders, Riverpod controllers, repository interfaces | Good: separates testable state/transport with limited layers | Add with the first feature; no empty framework scaffold now |
| Linux Device Preview plus real Android phone | Good for this Arch workflow: quick layout iteration without an emulator | Camera/lifecycle/release checks still require Android tooling/device |
| Small online-first client | Good for the presentation window | Defined uncertain-result recovery; no offline success claims |
| Foreground polling | Good initial tradeoff: uses existing HTTP without a socket service | Bounded/coalesced requests, background stop, durable backend notifications |
| Native tokens, browser sessions kept separate | Good: suits native devices and existing first-party web | Expiry/revocation/storage and JSON-aware account policy agreed |
| Backend capabilities and unknown-status handling | Good: compatible rollout and honest unavailable states | Server rechecks commands; no permission inferred from a UI flag |

These are recommendations for implementation, not evidence that the starter
already has them. User approval for this docs task does not authorize a new
external service, package installation, or backend rewrite.

## Selected frontend features: October 6, 2026

The user wants **Stop Mode, Parcel Finder and Doorstep Guide** in the Rider app.
They are selected for implementation planning; their screen behavior, acceptance
and dispatch explanation live in [FEATURE_DIRECTION.md](FEATURE_DIRECTION.md).

| Selected feature | Intended value | Remaining implementation decision |
|---|---|---|
| Stop Mode | Current stop, parcel, instructions, cash and action together | Accepted task-detail/actions; its saved-stop/sample map is implemented separately and does not enable GPS follow or in-app road routing |
| Parcel Finder | Show where this rider placed the parcel | Account/parcel binding, session-only or private persisted tags, cleanup and estimate |
| Doorstep Guide | Collection/entrance information visible before it is needed | Authorized instruction fields, update ownership, phase visibility and estimate |

Selection does not enable new dispatch, live GPS, ETA, native onboarding or
multi-parcel final-mile runs. Keep rider-claimed pickups and hub-assigned
final-mile work. Existing limits and coverage semantics require current source
review before each integration slice.

## Open decisions before coding their feature

| Decision | Recommended starting answer | Why it needs agreement |
|---|---|---|
| Exact presentation date and available weekly hours | November 21 target; reserve November 20, compare capacity with the 315-hour baseline plus selected additions | Date/availability are unconfirmed; backend work also takes time |
| API origin, staging access and contract owner | Existing first-party HTTPS origin; backend owns spec, both review examples | Do not invent a production hostname or configure another developer's deployment |
| Native registration/resubmission | Existing first-party web flow for first version, native holding view | Fully native KYC adds substantial validation/private upload work |
| Token expiry and password/restriction revocation | Explicit expiry, re-login initially, per-device revoke | Security/usability policy; default never-expiring tokens are insufficient |
| Proof types, byte/pixel limits and retention | Backend-configured purpose-specific limits; genuine private immutable proof | Storage/proxy/device limits must match; no guessed legal retention policy |
| Recipient fields and failure codes | Map the normative labels to tested machine codes | Current backend evidence fields/gaps require agreement |
| Command retention and restart recovery | Seven-day lookup proposal plus tested minimal pending-intent storage | Needs persistence, privacy cleanup, and replay semantics |
| Barcode format and Android device floor | Read actual waybill format and test a real intended device | Plugin minimum SDK, image quality and APK size affect selection |
| Cash remittance workflow and earnings rate | Server ledger contract; no invented rate or payout endpoint | Financial phase must define receiver evidence and final-mile attribution |
| Embedded map and provider | Current Rider map uses OpenStreetMap tiles, Leaflet on Android and FlutterMap in Linux Device Preview | Public tile service is best-effort without an SLA; approve a suitable hosted or self-hosted provider before broad rollout |

When deciding, update the relevant contract, acceptance cases, dependency and
estimate together. Reject a choice that needs new infrastructure or an
unavailable backend phase unless scope/capacity is explicitly approved.

## Ideas with a clear value or cost

| Idea | Judgment | Value, cost and stopping point |
|---|---|---|
| Scan → review parcel → explicit confirm | **Recommended within custody work** | Reduces wrong-parcel taps; only matching real scans and server evidence can advance custody |
| A clear “Return to hub” next step after failure | **Required core behavior** | Preserves responsibility and hub-owned retry; not an optional feature |
| Safe proof draft preservation and Android lost-data recovery | **Recommended, bounded** | Avoids retaking evidence after normal rejection/process interruption; private cleanup/account binding required |
| Pending-command privacy and recovery | **Implementation exists; policy remains open** | `SecureCommandJournal` stores the full exact `CommandIntent`, including its action body, in scoped secure storage; proof bytes are separate. Unknown intents survive logout and are not purged when the seven-day retry window closes. See the [source audit](plans/rider-workflow-recovery/PRIVATE_DATA_LIFECYCLE.md); M01.06 and M16.02 remain planned. |
| External directions with address fallback | **Recommended for stop details** | Useful without a map server, live location or guessed pin; explicit tap and valid destination |
| Embedded selected-stop street map | **Implemented as a saved-stop/sample map** | Android and Courier web use Leaflet; Linux Device Preview uses FlutterMap; OSM tile disclosure is in place; the public tile service has no SLA, so production-provider acceptance remains open |
| Fully generated API client | **Wait for stable contract** | Helps many models later, but adds build tooling and generated review churn now; hand-written DTOs first |
| Local encrypted history database | **Defer** | Offline reading may help later, but adds storage/privacy/migration complexity; memory-only initial scope |
| Full offline custody/write synchronization | **Defer; high correctness risk** | Ownership/capacity/source state can change while offline; server confirmation remains mandatory |
| Push notifications or realtime sockets | **Defer; separate approval** | Useful background alerts, but requires delivery services/credentials/device lifecycle and maintenance; durable in-app records first |
| Biometric app unlock | **Optional after auth stability** | May protect local access; cannot authorize server work, clear suspension, or replace token expiry |
| Background GPS, ETA and optimized route batches | **Outside baseline** | Adds permissions, battery/hosting/privacy and dispatch policy; no evidence it fits this presentation window |
| AI routing/dispatch or a second backend | **Do not add for this scope** | No core requirement justifies cost or duplicated authority |
| iOS release | **Later scope** | Flutter UI may transfer, but signing/build/device verification needs macOS/Xcode and an iOS runner |

“Good idea” means it solves a real rider problem at an acceptable cost. It does
not mean it is approved, implemented, or worth delaying custody/finance checks.
Prioritize trustworthy next actions and recoverable evidence over new dashboards.

## Decision log format

For future approved decisions record date, problem, chosen option, owner,
affected source/API/screens, estimated impact and required verification. Keep
private work-tracker details in the local guide only. Record measurable findings
after implementation; do not claim speed/RAM/battery gains from package choice
alone.

The October 5 documentation decision is to preserve the web product contracts,
propose a small native client/API adapter plan, and defer implementation until
its next scoped task. No deployment or optional external service is changed.
