# Philippines map-focus evidence

October 14, 2026. Branch `feat/home-philippines-map-focus`, from merged mobile
`main` `5016b03` (HDB-02 / PR 18).

## Implemented behavior

Home uses a labelled PH overview and bounded camera (zoom 4–19). A country-shaped
mask hides neighbouring basemap artwork. Current navigation takes focus priority,
then the selected stop, then the returned queue, then the country overview. A
navigation frame includes the rider, destination and returned road geometry.
Panning suspends automatic framing until explicit Recenter; tab/foreground and
keyboard visibility preserve the existing navigation and map cancellation rules.

Selected/current stops remain one unchanged pin when search or another list hides
their rows. Missing/outside-outline destinations retain their saved coordinates,
address/details and external directions. An outside-outline warning refers to the
display approximation, not legal country membership or server eligibility. There
is no guessed hub, IP origin, automatic geocoding, task outcome or location history.

The default streets use Geoapify osm-bright-smooth at standard density. Sharper
labels are an explicit HD choice using native @2x images with one request per
logical tile. Style/density paths have distinct byte/image cache identities;
changing detail cancels only the old tile scope and preserves pan/route/navigation.
Tiles wholly outside the display envelope decode locally without provider work.
Existing scheduling, memory bounds, bearer isolation, retry/cooldown and corrupt
byte recovery remain. Controls/feedback/credits sit outside the map image so they
do not cover its pins and labels. Persistent caching remains a future decision.

## Boundary and provider evidence

Source: OCHA Philippines / NAMRIA (2020), via geoBoundaries
`PHL-ADM0-24100683`, pinned release `9469f09`; CC BY 3.0 IGO and CC BY 4.0.
The derivation checks the full source SHA before writing, uses Shapely 2.1.2
topology-preserving simplification, and verifies valid geometry with every source
island retained. No Python dependency enters the Flutter app.

- Full source: 17,401,908 bytes / 393,458 vertices / 2,852 polygons.
- Supplied simplified source: 1,926 polygons; not used because it omits islands.
- Bundled derivation: 3,881,449 bytes / 98,879 vertices / all 2,852 polygons.
- Asset SHA-256: `2cb0ca5ec72cdc40b31212a31517579861e8f91b9b3a965b73fb3e7d837f5bad`.

The 0.0005-degree simplification is a cartographic approximation near shorelines,
not a service boundary or exact land survey. The app's PH outline credits expose
attribution, source, license links and modification notice. Full provenance and
regeneration are in [the asset register](../../../assets/maps/README.md).

Four sequential HTTPS samples used one public Manila tile and the existing
private key; no Bagoo bearer, rider fix or task was sent. All returned valid PNGs:

| Style | Density | Pixels | Bytes | Observed ms |
|---|---|---|---:|---:|
| positron | Standard | 256×256 | 61,292 | 1,616 |
| osm-bright | Standard | 256×256 | 95,146 | 278 |
| osm-bright-smooth | Standard | 256×256 | 102,118 | 339 |
| osm-bright-smooth | Native @2x | 512×512 | 272,113 | 587 |

The images were inspected for labels/contrast. The initial request includes a
different connection/cache situation; these samples are not a controlled speed
benchmark or phone/network acceptance. The sharper sample is about 2.7 times the
standard smooth sample's bytes, so HD is optional rather than the default.

## Source and verification

Backend `7d1790b` on `feat/hub-handover-recovery` was read only at activation and
completion, with its owner's hub work in progress. Native task service/OpenAPI
have no worktree change; the operations fingerprint remains
`8b09acf2e933441ee766820c94f65eafe1240c6c343b659e89487c6ab1e507eb`.
Buyer coordinates exist; seller/hub coordinates remain null. No backend branch,
file, migration, database, test, deployment or live operation was changed here.

Final full Flutter suite: **226 passed**, one expected configuration skip.
Analysis: clean. Ordinary configured Linux release and ARM64 debug APK builds:
passed. The normal account origin is Azure HTTPS; operational writes remain
disabled. No sample-production mode or fresh live operational login was used.

Maintained checks cover asset/isolate loading, malformed outlines, coordinate
order/islands, focus precedence, unchanged outside points, retained selected pins,
pan/Recenter, hidden/keyboard views, source changes during navigation, cache/
request/header isolation and quota recovery. There are 35 mask render checks:
every integer zoom 4–19 at 320/1000 widths, plus rotated fractional zooms at 390.
Their pixels preserve PH content and mask neighbouring land. Existing account,
Settings, operations, access revocation and navigation regressions also pass.

No USB phone was detected. Actual mobile-network cold/warm loading, phone label
readability, GPS/notifications/permission and screen-off behavior remain open.
Desktop synthetic render/provider samples and APK builds do not establish them.
Verified hub/seller coordinate integration remains [API-H06](../../api/HOME_DASHBOARD_NEEDS.md#api-h06).
HDB-03 and the rest of the operations/backlog scope remain separate.
