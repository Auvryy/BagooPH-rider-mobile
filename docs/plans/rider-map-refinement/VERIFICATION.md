# Map refinement verification

Verified October 22, 2026 on `feat/home-rider-map-style`, from merged mobile
`main` `b19a437`. The source stayed unchanged throughout the final analysis,
full test run and native builds; the ignored check receipt records matching
source fingerprints. Backend reference remained clean at
`99e5895f98159334e372df4f43659fda0bd43960`; no backend file, account, assignment,
command, database or deployment changed during this task.

## Final checks

| Check | Result |
|---|---|
| `flutter analyze --no-pub` | Passed, no issues |
| Full `flutter test --no-pub --reporter expanded` | **565 passed**, four expected skips; terminal `All tests passed!` |
| Opt-in map artwork suite | **11 passed**, actual cached Geoapify tiles/road geometry |
| Responsive Home regression after the keyboard correction | **38 passed**; included again in the full passing run |
| Ordinary configured Linux debug build, with Device Preview | Passed |
| Ordinary configured Android debug APK | Passed; `build/app/outputs/flutter-apk/app-debug.apk` |
| Artwork helper syntax and reuse of prepared cache | Passed; existing cache made zero additional provider requests |

The Android build retained the installed SDK XML-version warning; it did not
prevent compilation. No app window or physical device was needed for these
headless checks. A build is not physical GPS/service acceptance.

## Requirement evidence

| Selected requirement | Evidence |
|---|---|
| Dark, readable map close to the supplied visual direction | Actual Geoapify `dark-matter-dark-grey` artwork; charcoal controls, readable labels, outlined crimson route, distinct position dot and compact stop pins; independently inspected dark/daylight phone and wide renders |
| Keep the map on the Philippines | Existing island footprint/bounds retained; PH overview when no valid origin/stop exists; outside-country samples and outside-outline points retain truthful fallback; PH mask/coordinate-order tests pass |
| Automatically frame the rider area | Actual Home/controller integration accepts a fresh foreground fix and centers at zoom 15 before a distant queued stop; no route or parcel command starts from a sample |
| Foreground location is bounded | Snapshot tests cover 15-second timeout, stale/future/inaccurate/invalid fixes, source failure/end, permission denial/permanent denial/services off, hidden Home, account replacement/logout and late replies |
| Background navigation remains rider initiated | The Android foreground adapter requests no navigation notification/configuration. Before explicit Navigate, cancellation is awaited before the navigation stream prepares/subscribes; the existing navigation lifecycle/regressions pass |
| Panning and manual controls behave deliberately | A later snapshot cannot overwrite a panned camera; Recenter restores it. Navigation frames the rider at street level; Full route and Queue stops explicitly fit their respective coordinates |
| Style/density changes preserve work | Dark/daylight and HD replace cancelled tile scopes while retaining camera, route and active navigation. High-density displays select native 2x tiles; style/density cache isolation and provider-error tests pass |
| Linux stays honest | No automatic GPS source; only entered valid PH coordinates create a labelled Manual preview origin. Preview entry changes neither navigation nor parcel state |
| Small screens and accessibility | 375×812, 320×640 at 200% text/reduced motion, 844×390 landscape, 1200×500 and 1200×850; 48dp map controls, native zoom label/action, keyboard Enter activation, independent color contrast, normal scrolling and reachable attribution |
| Account/task behavior is preserved | Existing marker/card/detail, missing-coordinate, revoked-task/hidden-map, command, notifications, Messages, Trips, Settings and auth tests pass in the full run. Home samples retain no travelled history or backend upload |

Verification caught and corrected lost empty-search visibility when the keyboard
changed Home's layout. The search visibility/focus now survive that change;
portrait keyboard-constrained views still suspend map work. Short wide windows
retain scrollable map access without clipping the control rail.

## Provider and rendering evidence

The existing private client configuration successfully returned actual tile
artwork and a motorcycle road route between the fixed public sample points
`14.6, 121` and `14.606, 121.008`. Samples compare the provider's dark styles;
the selected grey style makes streets/water easier to distinguish. These are
software-test geography and fixture task data, not a rider journey.

Rendered PNGs, layout measurements, cached public artwork and final command
receipts are under ignored `build/map-refinement/`. The rendering helper waits
for native tile decoding before capturing. The public preparation tool accepts
only provider tile styles/coordinates, spaces requests below four per second,
uses the existing configuration privately and stops on errors including 429.
Key values and bearer sessions are excluded from tracked files and artwork
preparation logs. The existing setup contract for app client keys is unchanged.

## Remaining boundary

The client scope is complete and locally verified. Physical Android acceptance
must still check actual GPS, OS permission dialogs, notification absence
for Home, background/return, and the existing explicit screen-off navigation
service. [TESTING.md](TESTING.md) leaves those physical checkboxes open.

The source still supplies native coordinates only for buyer stops. Seller/hub
stops keep their address-first fallback; the map does not invent their position.
No new API/key/deployment, road-condition dataset or live operational acceptance
is claimed. This slice does not complete full M09 or Android release acceptance.
