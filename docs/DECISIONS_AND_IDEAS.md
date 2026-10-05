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

## Open decisions before coding their feature

| Decision | Recommended starting answer | Why it needs agreement |
|---|---|---|
| Exact presentation date and available weekly hours | November 21 target; reserve November 20, compare capacity with 130–204 client hours | Date/availability are unconfirmed; backend work also takes time |
| API origin, staging access and contract owner | Existing first-party HTTPS origin; backend owns spec, both review examples | Do not invent a production hostname or configure another developer's deployment |
| Native registration/resubmission | Existing first-party web flow for first version, native holding view | Fully native KYC adds substantial validation/private upload work |
| Token expiry and password/restriction revocation | Explicit expiry, re-login initially, per-device revoke | Security/usability policy; default never-expiring tokens are insufficient |
| Proof types, byte/pixel limits and retention | Backend-configured purpose-specific limits; genuine private immutable proof | Storage/proxy/device limits must match; no guessed legal retention policy |
| Recipient fields and failure codes | Map the normative labels to tested machine codes | Current backend evidence fields/gaps require agreement |
| Command retention and restart recovery | Seven-day lookup proposal plus tested minimal pending-intent storage | Needs persistence, privacy cleanup, and replay semantics |
| Barcode format and Android device floor | Read actual waybill format and test a real intended device | Plugin minimum SDK, image quality and APK size affect selection |
| Cash remittance workflow and earnings rate | Server ledger contract; no invented rate or payout endpoint | Financial phase must define receiver evidence and final-mile attribution |
| Embedded map parity | Implement after essential stop/directions; agree tile provider and configuration | Web Leaflet cannot be reused in Flutter; external service policy matters |

When deciding, update the relevant contract, acceptance cases, dependency and
estimate together. Reject a choice that needs new infrastructure or an
unavailable backend phase unless scope/capacity is explicitly approved.

## Ideas with a clear value or cost

| Idea | Judgment | Value, cost and stopping point |
|---|---|---|
| Scan → review parcel → explicit confirm | **Recommended within custody work** | Reduces wrong-parcel taps; only matching real scans and server evidence can advance custody |
| A clear “Return to hub” next step after failure | **Required core behavior** | Preserves responsibility and hub-owned retry; not an optional feature |
| Safe proof draft preservation and Android lost-data recovery | **Recommended, bounded** | Avoids retaking evidence after normal rejection/process interruption; private cleanup/account binding required |
| Minimal pending-command recovery after app restart | **Recommended with mutation work** | Lets rider verify a lost response without duplicate results; stores references only, not private proof/contact bodies |
| External directions with address fallback | **Recommended for stop details** | Useful without a map server, live location or guessed pin; explicit tap and valid destination |
| Embedded selected-stop street map | **Useful after core readiness** | Native parity and visual context; lazily load, attribution, provider policy and no default/live rider pin |
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
