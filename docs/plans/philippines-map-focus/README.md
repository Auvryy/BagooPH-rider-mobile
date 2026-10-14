# Philippines map and current-stop focus

Selected October 14, 2026 after HDB-02 was merged in PR 18. Branch
`feat/home-philippines-map-focus`, starting from mobile `main` `5016b03`.
State: **merged in PR 19**, mobile `main` `d6ff936`; physical acceptance remains open.
See [the evidence](EVIDENCE.md). Estimate: 6–9 client hours, 8-hour point
estimate; October 14–18 window. Suggested model: Sol 6.1 Medium.

This activates the [PH map recommendation](../home-dashboard-branch-plan/PH_MAP_FOCUS_NEXT.md)
as a separate map presentation slice before HDB-03. It owns no dashboard metrics,
custody action, new geocoding, fleet tracking or additional backend capability.
The five-batch operations plan and M09.07 location scope remain separate.

## Implemented client scope

- A labelled Philippines overview, bounded camera and country-shaped visual
  mask covering the source's islands. The display is not legal/service eligibility.
- Focus priority: active navigation, rider-selected stop, returned queue, country
  overview. Fit the rider/current road/stop when available; pan disables automatic
  framing until Recenter. Keep selected stops visible when local search hides rows.
- Missing/outside-outline coordinates keep their actual address and explicit
  fallback. Never guess hubs, clamp task coordinates or discard responsibility.
- Clearer streets; compare provider styles and standard/native-density samples,
  retain four requests/second, cache/cancellation/cooldown and visible attribution.
  Persistent caching is a future conditional decision after phone measurements.

## Source and ownership

Backend read-only review: `7d1790b` on `feat/hub-handover-recovery`, with its owner's
unrelated hub work in progress. Native task service still exposes buyer coordinates
only. Seller/hub coordinates remain null. OpenAPI SHA-256 remains
`8b09acf2e933441ee766820c94f65eafe1240c6c343b659e89487c6ab1e507eb`.
HDB-01/02 supply the selected recovery/lifecycle foundation; source evidence is
not a new Azure deployment or physical acceptance.

Coordinate ownership remains with [API-H06](../../api/HOME_DASHBOARD_NEEDS.md#api-h06).
The client can implement country display with the existing private map key.
Existing native authorization, profile choice, account/Settings behavior, explicit
Navigate/Stop and no-history rules remain mandatory. Writes remain gated.

Map boundary source: OCHA Philippines / NAMRIA (2020), via geoBoundaries
`PHL-ADM0-24100683`, pinned release `9469f09`. The full source has 2,852 polygons;
the supplied simplified source drops islands. Derive a topology-preserving copy
from the full source and retain all islands, license/provenance and source hash.
See [acceptance](ACCEPTANCE.md) for local versus device gates.

## Primary references

- [geoBoundaries PH metadata](https://www.geoboundaries.org/api/current/gbOpen/PHL/ADM0/)
  and [attribution](https://www.geoboundaries.org/index.html#usage).
- [CC BY 3.0 IGO](https://creativecommons.org/licenses/by/3.0/igo/) and
  [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
- [Geoapify tile styles/density](https://apidocs.geoapify.com/docs/maps/map-tiles/).
- Installed flutter_map 8.3.2 constraints, inverted polygon fill and pixel
  simplification; [polygon guidance](https://docs.fleaflet.dev/layers/polygon-layer).
- [Shapely topology-preserving simplification](https://shapely.readthedocs.io/en/2.1.2/reference/shapely.simplify.html)
  is asset-generation tooling only, not a Flutter runtime dependency.
