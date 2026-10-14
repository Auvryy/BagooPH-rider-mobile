# Next map improvement: Philippines view and current-stop focus

Requested after HDB-02 on October 13, 2026. **Recommendation only; not activated
by the lifecycle branch.** Integrate this into the next selected Home overview
delivery, or select a separate `feat/home-philippines-map-focus` branch before it.
Do not create another execution record until that work is requested.

## Recommended behavior

1. Start with a labelled Philippines overview when there is no known current
   stop. When trusted coordinates exist, prefer the current navigation task,
   then the rider-selected stop, then the returned queue/assigned hub. Fit the
   rider and current destination/road when useful instead of repeatedly zooming
   out to the whole country. Preserve manual pan until Recenter.
2. Constrain camera movement/zoom to a deliberate Philippines/service-area view.
   A rectangle alone still contains water and neighbouring land; it does not
   provide a strict country-shaped display. For the requested PH-only appearance,
   add a visual mask using a reviewed, licensed Philippines multipolygon,
   including islands, and verify it at phone/tablet widths and every supported
   zoom. Decide the displayed service footprint with the product/API owner;
   a display mask is not a legal boundary or a task-authorization rule.
3. Keep the current stop pinned even when local search hides its queue row.
   Explain the difference between the selected task and the filtered list.
   Missing or questionable coordinates retain the actual address and a clear
   unavailable-map state. Never guess a hub, move an outside point into the PH
   bounds, infer the rider from IP geolocation or silently discard a responsibility.
4. Review street-label contrast and map size using actual phone density. Compare
   the current Positron style with a clearer Geoapify style and native high-density
   raster tiles before selecting one; measure bytes, credits, latency and rendering
   rather than assuming a larger image is faster. Keep attribution visible.
5. Measure a complete cold/warm dashboard on the rider's phone and mobile network.
   Keep the four-request/second scheduler, visible-viewport loading, cancellation
   and bounded retries. Consider a bounded HTTP-aware persistent basemap cache
   only after reviewing provider terms, retention and cache clearing; do not
   confuse cached streets with offline task authorization or record GPS history.

## Data and ownership

Buyer-stop coordinates are already present in the inspected native contract.
Seller/origin-hub/destination-hub coordinates are still null; useful hub-first
focus requires the API owner to expose verified saved coordinates under the
existing privacy/role rules. Track that request in
[API-H06 and the Home checklist](../../api/HOME_DASHBOARD_NEEDS.md), with no client
geocoding loop or fabricated success. Country/coordinate validation for business
eligibility remains server-owned. UI camera limits/masking can be built locally.

The later map branch needs a reviewed boundary asset/license, explicit focus
precedence, stop-outside-filter tests, missing/outside-coordinate fallback,
pan/Recenter/rotation/keyboard tests, provider-quota tests and physical cold/warm
measurements. It adds no multi-stop optimization or automatic arrival/outcome.

## Primary technical references

- Installed `flutter_map` 8.3.2 camera constraints distinguish `containCenter`
  from `contain` (viewport edges). See the
  [CameraConstraint API](https://pub.dev/documentation/flutter_map/latest/flutter_map/CameraConstraint-class.html).
- Geoapify documents map styles, raster endpoints and high-density variants in
  its [map-tile reference](https://apidocs.geoapify.com/docs/maps/map-tiles/).
- [flutter_map caching guidance](https://docs.fleaflet.dev/layers/tile-layer/caching)
  explains that dedicated tile providers may need their own cache integration.
  Our custom Geoapify provider currently uses a bounded in-memory cache; it does
  not obtain persistent caching automatically from the standard network provider.

Suggested model: Sol 6.1 Medium for the bounded map presentation/focus slice,
with High for a separate coordinate/authorization/caching review if needed.
