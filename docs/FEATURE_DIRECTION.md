# Selected Rider frontend direction

Selected for implementation planning on **October 6, 2026**: **Stop Mode,
Parcel Finder, and Doorstep Guide**. The user wants these three experiences
in the Rider app. Their selection is a product decision; the Flutter starter
does not implement them yet.

Build them around the existing pickup, delivery, evidence and contact flows.
[RIDER_FLOW.md](RIDER_FLOW.md) remains the operational contract.
[SOURCES.md](SOURCES.md#october-6-dispatch-and-selected-feature-review) records
the current scoped website evidence. Unselected research ideas are optional
future work.

## 1. Stop Mode

**User outcome:** a stopped rider can understand and finish the current stop
from one focused screen.

Open it from a selected task with “Work this stop.” Show the full parcel
identifier, current stage, authorized destination, relevant instructions,
exact COD when applicable, contact actions and one permitted primary action.
Keep essential information above a compact map; address and directions work
independently when tiles or coordinates are unavailable. Pickup changes from
seller to origin hub after collection. Final-mile changes from destination-hub
collection to the saved buyer destination after authorized departure.

Reuse M04 task detail, M06–M08 commands and M09 directions/contact. Stop Mode is
a presentation of those responsibilities, not a new status, route optimizer
or assignment mechanism.

**Acceptance:**

- Available pickup is a preview with “Claim pickup”; the claim does not imply
  that physical collection already happened.
- Claimed pickup shows seller collection; collected pickup shows the assigned
  origin hub and “Awaiting hub intake” until the hub confirms receipt.
- Assigned final-mile work shows destination-hub collection, then the saved
  buyer destination, required evidence and exact cash after departure.
- Failure shows the authorized return/recovery instruction. Recorded delivery
  shows a receipt and keeps buyer confirmation separate.
- Returning from navigation, scanning or the camera refreshes the selected
  parcel and permissions. Stale assignment, missing destination and uncertain
  submission have different useful messages.
- Controls remain reachable with bottom navigation, keyboard and 200% text;
  320–430 logical-pixel layouts and real Android use require verification.

## 2. Parcel Finder

**User outcome:** identify where an authorized parcel was placed without
searching every compartment.

Let a rider select a physical slot such as “Top box / Left,” “Top box / Right”
or “Bag 2” from a small motorcycle/bag diagram. Show the chosen slot and a
large distinguishing tracking suffix in Stop Mode, with the full identifier
available and a real matching scan where supported. Start with the supported
multi-pickup flow; keep this useful for a single final-mile parcel too.

A slot is a personal organization label. It does not prove a scan, load,
assignment or custody handoff. Multiple parcels can share a slot.

**Acceptance:**

- A tag binds to this rider and parcel; changing the selected parcel never
  carries another parcel's tag into its screen.
- Unset slots show “Location not set.” Editing or clearing a slot leaves the
  server-owned assignment and custody unchanged.
- Preserve labels through ordinary task refreshes. Clear them when scoped work
  ends or account authorization changes, using the agreed cleanup policy.
- Decide session-only storage versus private persisted labels before coding.
  If persistence is selected, agree retention, logout/account cleanup and
  restart behavior; do not silently add general offline parcel storage.
- Wrong or unreadable scans have recovery guidance and cannot confirm a match.
- A multi-parcel final-mile load/run is additional dispatch scope. The reviewed
  backend currently limits new final-mile assignment to a rider without other
  active courier work; this feature does not change that rule.

Reuse M06.06–M06.07 and M07.03 for scanning, M04 selection and M16 private-state
cleanup. Compartment labels are additional scope whose storage and effort need
a bounded feature breakdown.

## 3. Doorstep Guide

**User outcome:** reach the authorized collection point or entrance, rather
than stopping at an ambiguous map pin.

Show authorized landmark, entrance, floor/unit and access instructions before
opening directions and again during handoff. Keep a useful text-first layout.
For pickup, use the seller's collection instructions; for final-mile, use
instructions for the order's saved buyer destination. Hub stops use the hub's
own authorized receiving instructions.

The immutable destination remains visible. Clarifications do not change the
recipient, destination area, assigned hub or COD amount. Entrance photos and
reporting wrong pins are later additions unless separately selected.

**Acceptance:**

- Show supplied instructions with their purpose; missing data means “No extra
  instructions provided,” not a guessed landmark.
- The API owner agrees instruction fields, their author/update authority and
  visibility per parcel phase before integration. Field names in a design are
  not existing backend capabilities.
- Render notes as plain text with accessible wrapping. Explain which address
  directions will use and retain copying/contact fallback.
- A clarification cannot silently reroute the order. Changes that affect the
  destination use the owning review/exception flow.
- Refresh authorized notes when returning to the task. Hide private instructions
  on account change or when assignment access ends.

Reuse M09 stop/address/contact presentation and M01 task-detail agreement.
Instruction data is a new dependency; the existing address-only contract does
not establish that these fields are already supplied.

## How work reaches a rider

There are three different concepts that earlier wording called “assignment”:

| Concept | Who decides? | What it means in the Rider app |
|---|---|---|
| Company/hub/area placement | Authorized logistics management after platform approval | Where this courier is eligible to work; not ownership of every parcel there |
| Seller pickup claim | Eligible rider chooses an available ready parcel; backend accepts atomically | The successful claim creates the pickup assignment; collection is a later handoff |
| Final-mile assignment | Authorized destination-hub/logistics operator selects an eligible rider | That parcel appears in the selected rider's delivery queue; hub departure is a later handoff |

Pickup work is not automatically allocated by the destination barangay.
Final-mile uses the destination hub and applicable barangay coverage. A
barangay may have several eligible riders; an operator chooses a specific one.
Assignment by an operator and automatic allocation by an algorithm are
different capabilities.

The source snapshot records current limits and nullable barangay behavior.
Do not describe every pickup as barangay-filtered, every final-mile rider as
having a mandatory exact barangay, or several simultaneous final-mile parcels
as established backend behavior. Agree missing coverage semantics before a
mobile contract claims stronger enforcement.

## Recommended dispatch approach and its tradeoffs

**Keep the current hybrid: rider-claimed seller pickups and hub-assigned
final-mile delivery.** This recommendation fits the project's current hub
custody model. Selecting the three frontend features does not change dispatch.

| Approach | Benefit for this project | Cost or limitation |
|---|---|---|
| Rider claims eligible pickups | Rider chooses workable seller collections; lower manual dispatch effort; existing bounded multi-pickup behavior | Attractive jobs may be claimed first; difficult work may wait; the board needs fresh availability and clear capacity |
| Hub assigns final-mile parcels | Hub knows what is physically ready; identifies an accountable rider; can consider area and workload | Less rider choice; depends on timely operator decisions; poor allocation can increase travel or waiting |
| Applicable barangay coverage | Local knowledge and understandable delivery areas; can help future grouping | Uneven demand, unavailable riders and nearby cross-boundary stops need a defined policy; a barangay name is not route optimization |

The UI should explain the assigned hub, area when configured and the next
action. Future exception requests or suggested pickup priorities can help
coordination, but require their own accepted workflow. Riders cannot take
another rider's parcel or reassign work through a frontend-only choice.

## Current flow to explain during the demonstration

1. Buyer checkout creates the commercial order and logistics destination.
2. Seller confirms, prepares and marks the parcel ready for pickup.
3. An eligible on-duty rider claims from the available pickup board. The
   successful claim creates ownership; the seller handoff then records pickup.
4. The pickup rider brings it to the assigned Origin Bayan Hub. The hub receives
   it and ends that pickup responsibility.
5. Logistics carries it through at least one Mother Hub to the Destination
   Bayan Hub, preserving the required recorded custody.
6. The destination hub sorts doorstep work into its delivery area/bin and
   assigns a specific eligible final-mile rider.
7. The assigned rider collects/departs from that hub, then records recipient
   handoff, required proof and exact COD where applicable.
8. Delivery is recorded. The buyer confirms receipt separately; collected cash
   requires remittance and platform reconciliation before eligible settlement.
   Buyer confirmation and cash remittance can happen in either order; both
   required gates must finish before settlement.

A failed delivery keeps the parcel with its rider until the destination hub
receives the return. Hub-approved retry or reverse logistics follows the
operational contract. Self-pickup at the destination counter is a separate
branch without a final-mile rider.

This is the current documented role sequence. Genuine Rider waybill input,
exception persistence, complete COD ledgers and the native client still need
their respective implementation evidence; the sequence is not a whole-system
readiness claim.

## Integration and planning

| Experience | Existing major areas | Additional decisions before implementation |
|---|---|---|
| Stop Mode | M02, M04, M06–M09, M16 | Accepted task-detail/actions; optional embedded-map decision M09.07 |
| Parcel Finder | M04, M06, M07, M16 | Compartment model, tag ownership, storage/cleanup and incremental effort |
| Doorstep Guide | M01, M04, M09, M16 | Authorized instruction data, ownership, phase visibility and incremental effort |

The existing 180-card/63-batch catalog and 315-hour estimate remain the
**baseline**, not an estimate for all selected additions. Fold Stop Mode's
existing behavior into the relevant slices; separately estimate Parcel Finder
and Doorstep Guide before adding their executable cards. No dates, deployed
API or device acceptance are implied by this planning selection. Keep the
November 20 freeze and November 21 presentation target.

Implement the accepted shell/task detail first, then Stop Mode, then the
bounded Parcel Finder and text-first Doorstep Guide. Verify each included
capability against the current web role, source contract and real Android
behavior. Maintain source synchronization through [SOURCES.md](SOURCES.md)
and planning through [TASK_TRACKING.md](TASK_TRACKING.md).
