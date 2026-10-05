# Product scope and presentation goal

## Purpose

Help a stopped rider identify the next authorized task, reach the correct stop,
record trustworthy evidence, and understand remaining parcel and cash duties.
Pickup and delivery are assignment phases of one `courier` account; they do not
require separate applications or account conversion.

This is a practical project demonstration with a small set of accounts, shops,
hubs, and contiguous land routes. Nationwide deployment, enterprise throughput,
and new infrastructure are not presentation requirements. The working date is
November 21, 2026, with verification and rehearsal completed by November 20.

## Actor boundaries

| Actor | Responsibility | Rider application boundary |
|---|---|---|
| Buyer | Checkout, owned tracking, receipt confirmation | Rider records delivery; only buyer completes an order |
| Seller | Preparation, waybill, ready state, seller return receipt | Rider collects the assigned ready parcel |
| Pickup courier | Claim, seller handoff, bring parcel to origin hub | Same app and role as final-mile courier, separate assignment |
| Final-mile courier | Assigned hub departure, recipient handoff, outcome, cash held | No self-assignment to another rider's delivery |
| Hub Handler | Facility scans, failed-parcel intake, counter release | Rider waits for authenticated hub receipt |
| Logistics Company Admin | Own placement, operational assignment, manifests, approved recovery | Managed hub/vehicle placement is read-only in the app |
| Platform Admin | KYC, governance, financial reconciliation, controlled corrections | Rider cannot approve self, clear restrictions, or reconcile money |

## Presentation baseline

| Area | Required behavior | Dependency |
|---|---|---|
| Sign-in and account holding | Existing courier login, truthful approval/restriction/placement state, logout | Mobile auth and shared access policy |
| Tasks | Eligible pickup board, active assignments, clear stage and current stop | Scoped query resources and capacity rules |
| Duty | One confirmed availability control; existing work remains reachable | Server availability persistence |
| Pickup | Atomic claim, matching waybill, server-confirmed seller handoff, wait for origin intake | Stronger evidence and backend custody tests |
| Delivery | Assigned waybill scan-out, exact COD, recipient evidence, proof preview and confirmed result | Outcome validation, proof privacy and idempotency |
| Failure and recovery | Allowed reasons, return instruction, hub-owned retry/RTS | Backend exception phase; unsafe actions stay disabled until ready |
| Trips | Scoped recorded journeys and paginated history | Stable history resource and final-mile attribution |
| Messages | Authorized phase-linked conversations, safe drafts and selected-thread reads | Messaging adapter and stale-phase rejection |
| Notifications | Durable records/queues, correct read state and links | Backend notification phase; polling does not create notifications |
| Profile | Real account data and managed placement, permitted contact/password actions | Shared validators; no role conversion or self-approval |
| Cash and earnings | Separate held/remitted/reconciled cash and confirmed earnings | Backend financial phase; no guessed balances |

Native registration and KYC resubmission are an **open scope decision**. The
recommended first version uses the existing first-party web entry for those
flows and password recovery, then returns to native sign-in/holding. Open it in
the system browser, keep credentials out of URLs, and let web authentication
remain separate. A mobile registration API must be explicitly planned if a
fully native onboarding demonstration is required.

Maps enhance the baseline when approved and configured; textual stops and
external directions must work independently. The web rider map contract needs a
Flutter implementation decision, not a copied Leaflet component.

## Screens and states

- **Tasks:** Pickups, deliveries, and available work; relevant stop, parcel,
  exact cash due when permitted, one primary action, and a compact duty header.
- **Trips:** Returned history and recorded checkpoints, with real filters and
  pagination. Do not label estimates as paid earnings or lifetime performance.
- **Messages:** Conversation list to detail on phones; acknowledgements cover
  only displayed messages in the selected authorized thread.
- **Profile:** Courier identity, reviewed status, actual company/hub/vehicle
  data, permitted settings, logout, and clear missing-field explanations.
- **Holding/recovery:** Pending, rejected, approved but unplaced, off duty,
  suspended, expired session, unavailable backend, and controlled recovery each
  have different instructions and capabilities.

Every data view needs loading, empty, error, refresh, stale, and success states.
Use a returned empty list for “No tasks”; a failed request means tasks could not
be loaded. Missing hub data means unassigned/unknown, never a default city.

## Presentation and accessibility

Carry over the latest rider direction: `#E00D42` accent, `#FFFAFB` canvas, white
working surfaces, restrained shadows/outlines, and 8 logical-pixel corners.
Circle/pill shapes remain appropriate for avatars, dots, and the duty switch.
Use Plus Jakarta Sans, bundled as a licensed font asset when implemented; the
starter currently uses Flutter's default font.

Use labelled Tasks/Trips/Messages/Profile navigation, 48 logical-pixel minimum
standalone touch areas, wrapping addresses, safe areas, visible focus, and
accessible status text. Validate 320–430 logical-pixel layouts, large text up to
200%, keyboard access on previews, screen-reader labels, and reduced motion.
Do not copy desktop web breakpoints into native navigation automatically.

## Outside the baseline

No live GPS, automatic ETA, AI dispatch, route optimization, maritime/air freight,
new warehouses, external order push/SMS/email services, advanced analytics,
wallet withdrawals, role migration, or full refund/dispute modules. No background
offline custody queue that claims parcel handoffs succeeded without the server.
iOS is a later target requiring Apple tooling; the current scaffold has no iOS
runner. Evaluate additions in [DECISIONS_AND_IDEAS.md](DECISIONS_AND_IDEAS.md).

The [web documentation map](https://github.com/Auvryy/BagooPH/blob/main/docs/README.md),
[courier contract](https://github.com/Auvryy/BagooPH/blob/main/docs/COURIER_FLOW.md),
and [rider design](https://github.com/Auvryy/BagooPH/blob/main/docs/RIDER_UI_DESIGN.md)
are the source boundaries for this adaptation.
