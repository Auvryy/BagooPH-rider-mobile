# OPS-02 — Actual scan and physical parcel outcomes

State: **planned, not activated**. Needs OPS-01, its durable command foundation,
real camera/scanner/proof adapters and the [deployment gate](DEPLOYMENT_GATE.md).
Associations: B06-B, selected B06-C instructions, B07-A–B07-E, B08-A and supported
return presentation; inspect M09 stop/directions and M02 platform prerequisites.
These associations do not activate unsupported release/restricted-recovery cards.

## Contract and implementation slices

POST `rider/tasks/{task}/pickup`, `/depart`, `/deliver` and `/fail` using fresh
server action hints and the exact submitted scan. Pickup uses owned pickup phase;
departure/outcomes use owned final-mile phase.

1. Select/install a native scanner only when this slice is activated. Test real
   barcode capture, permission denial, cancellation and another parcel's barcode.
   Typed/fake scanner inputs remain test-only; never send stored tracking data as
   if the rider scanned it. Server normalizes ASCII waybills, not Unicode lookalikes.
2. Submit pickup/depart with `expected_version`, `barcode` and optional notes.
   Seller handoff differs from origin-hub intake; destination-hub departure differs
   from hub-owned assignment. Display the refreshed custody/stop and owning actor.
3. Delivery uses multipart original proof bytes, scan/version, recipient and exact
   `cash_received`, `change_given`, `cash_confirmed`. Let HTTP create the boundary.
   New native delivery is **COD-only**; unsupported payment hints stay disabled.
   Rider delivery does not complete the buyer's commercial order.
4. Failure uses an allowed reason, required notes, location and original proof.
   Follow returned attempt count/limit and return hub. A failed attempt retains
   rider custody until hub receipt; rider cannot approve retry, RTS or hub intake.

Proof must be genuine JPEG/PNG/WebP, at most 5,242,880 bytes. Retain original bytes
for uncertain replay; re-encoding creates a different intent. Preserve privacy,
resource/action/version, durable key and request/result uncertainty on restart.
Future file ownership: scanner/proof platform components, parcel repositories and
outcome controllers/views; coordinate changes to the common journal/transport.

## Finish evidence

- Local contract/controller tests cover correct/wrong scan, stale/terminal work,
  proof type/limit/storage rejection, exact COD, failed attempt and timeout replay.
- Actual Android camera/scanner, permission/cancel and proof selection work with
  real authorized test parcels; no gallery/typed substitution is presented as scan.
- Azure pickup/depart/delivery/failure results match the hub/buyer/cash records and
  original command result. Replays add no extra outcome, attempt or collection.
- Buyer completion, return-hub receipt and retry/reconciliation remain separate
  actors' actions. Native ordinary/restricted gates continue to enforce that.

Do not claim complete from mocked success or an APK build. Historical public
proof cleanup is a separate operator-reviewed release gate, not authorized here.
