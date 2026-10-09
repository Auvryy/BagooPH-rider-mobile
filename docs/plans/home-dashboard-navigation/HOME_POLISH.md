# Home and map refinement

Selected after the user reported updating Azure on October 9, 2026. This is a
presentation and map-interaction refinement within the existing selected plan,
linked to [M04/M05/M09](../../TASK_TRACKING.md) and [OPS-01](../native-operations/01-home-duty-pickups.md).
It preserves the accepted API, custody rules, account/Settings behavior and
explicit navigation lifecycle. It does not activate later parcel/finance batches.

## Resulting behavior

- Compact greeting, hub, duty and readable eligibility. Counts appear on the
  three full-name queue choices. Unknown counts remain unknown. The first load
  favors an existing responsibility; an explicit rider choice persists across
  refresh. Off-duty owned work remains reachable.
- Compact stop rows, expandable search and a selected stop summary with the
  complete authorized address, next instruction and exact recorded COD when
  returned. The task panel has a visible handle and expand/collapse control.
  Large text stacks required controls rather than requiring horizontal scrolling.
- Phones use an expandable panel; wide windows place it beside the map. Short
  keyboard-constrained views retain scrollable task access. Search survives a
  window-size change. Account changes still dispose private UI state.
- The map frames valid returned stops on load and focuses pin/card selection.
  Recenter, Show stop, Show queue stops and Show full route account for the panel.
  Panning disables GPS follow until Recenter. Selection does not start GPS.
- Fresh detail overrides stale list coordinates. Missing coordinates remove the
  selected pin and retain its address. Explicit hidden-task responses remove the
  cached task/pin and stop its navigation; changed current destinations also stop
  the old route. No guessed pin or substitute straight route is introduced.
- Stable tile-provider identity retains the existing shared provider scheduler
  and cache across UI refreshes. Map attribution stays outside the panel and uses
  the app's readable font. Existing permission, Stop and authorization timers are
  preserved.

## Source and live data evidence

Reviewed backend main `5068c66`, including the merged corrected Home capability
source. The exact Azure checkout and operator migration commands were not read
independently in this slice. The operator reported rollout; fresh native Flutter
login now advertises operations version 1, Home and all three queue reads pass
through the real shared transport and typed adapter. Returned counts and queue
sizes are all zero for the authorized existing test rider. Its Flutter verification
session was logged out. No assignment, duty, parcel or cash writer was submitted.
A preliminary generic HTTP probe hit edge protection; its logout was not confirmed.
No bearer was saved or printed. That cleanup limitation is separate from the
successful native read check and is not presented as a clean token-count audit.

This proves deployed native read behavior for that actor. It does not prove an
owned task detail response, live writes, every source migration, an exact deployed
commit or physical Android navigation. Operational writes remain gated.

## Finish evidence

Meaningful checks cover pin/card/detail selection, camera zoom, attribution
placement, panel/search/queue interactions, missing/freshly removed coordinates,
hidden-task navigation stop, off-duty responsibility priority, explicit queue
choice, large text and wide-to-phone resize. Full regression, analysis and native
build evidence is recorded in [EVIDENCE.md](EVIDENCE.md).

Before/after phone and wide renders use isolated synthetic tasks and cached public
Geoapify tiles with visible attribution. They review layout, fonts and map geometry;
they are not production task, GPS or custody evidence. Images stay in ignored
build artifacts, and no provider key appears in the screenshots or tracked files.
