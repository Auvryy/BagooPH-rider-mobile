# Home dashboard and live route navigation

Selected October 9, 2026. This package owns the chosen map/location extension,
linked to [OPS-01](../native-operations/01-home-duty-pickups.md) and
[M09.07](../../backlog/M09.md#m09-07). It supplements the
[five-batch API plan](../native-operations/README.md), [task map](../../TASK_TRACKING.md)
and [source rules](../../SOURCES.md).

The user selected local implementation and verification while credentials and
operator evidence are unavailable. Local checks never establish Azure or physical
Android acceptance. The later [Home refinement](HOME_POLISH.md) records successful
native Azure Home/queue reads and the updated UI, with remaining gates separate. Production writes remain disabled until deployment acceptance
is recorded; ordinary Azure account and Settings access remain available.

## Source and prerequisites

Backend main `1d785aab7262c88f14e539b7f1bad58f90e180ec`, reviewed October 9:
accepted operations contract/OpenAPI/examples, account discovery, Rider task and
command services/controllers, courier scope and current deployment roadmap.
No backend edits or deployment are authorized here. Reviewed mobile baseline
`d16ca35`. The [deployment gate](../native-operations/DEPLOYMENT_GATE.md) requires
actual deployed revision, additive migrations and fresh authorized bearer checks.
Source availability does not clear that gate or the backlog's STAGING/ANDROID gates.

Pickup stops are seller or origin hub; final-mile stops are destination hub or
frozen buyer destination. Current source provides coordinates only for buyer stops.
Missing coordinates retain the server address and never create a guessed pin.

## Phases and ownership

1. Live Home data: exact DTOs, server counts/capacity/eligibility, paginated
   available/owned queues, fresh detail, duty and claim with protected durable
   account-scoped UUID intents, command reconciliation and session cleanup.
2. Map-first Home: flutter_map, Geoapify raster tiles, linked pin/card selection,
   normally scrolling three-queue task section on phones and a side panel on
   wide windows, task address/details and external directions.
3. Road line: separate Geoapify client, correct GeoJSON conversion, registered
   vehicle profile or explicit choice, good-fix validation, local trimming,
   cancellation, recenter and bounded rerouting.
4. Android navigation: rider-started geolocator foreground service, contextual
   precise/notification permissions, ongoing notification, persistent controller,
   authorization refresh and explicit Stop. Linux uses a labelled manual origin.

Shared transport, Home/workspace and account discovery have one implementation
owner. Settings behavior, scanning, outcomes, messages, finance and backend state
transitions remain their separate batches. No multi-stop optimization, voice
engine, automatic arrival/outcome, duty-triggered tracking, reboot start or
location-history storage/upload is included.

## Durable intent retention

The protected journal is keyed by API origin and account ID. It stores only UUID,
action/resource, original version or desired duty boolean and creation time.
It survives logout/restart, remains inaccessible to other accounts, and is removed
on validated committed results or definite rejected writes. Unknown, conflicting
or expired intents remain available for same-account reconciliation; they are
never silently replaced. A same-key retry requires an explicit rider action.
No credentials, contacts, proof or travelled coordinates are in this journal.

## Verification and open gates

Local evidence and remaining external requirements are recorded in
[EVIDENCE.md](EVIDENCE.md). Configuration and the backend/device handoff are in
[SETUP_AND_ACCEPTANCE.md](SETUP_AND_ACCEPTANCE.md). Keep source, local tests/builds, Azure and physical
Android distinct. Each phase is reviewed locally before the next implementation.
