# Rider street map and neutral controls

Scope: refine the current Rider interface using restrained card borders, neutral surfaces, standard rounded controls and a light street map. Keep Bagoo's own red accent and Plus Jakarta Sans. Reference projects are read-only design examples; no reference project assets, accounts, API secrets or business rules are copied.

The native app retains its existing flutter_map renderer, cached Geoapify tile transport, OpenStreetMap attribution and real Geoapify road geometry. Leaflet is used in the web client; adding a browser renderer inside Flutter is unnecessary. No straight connector is substituted for a missing road route. Location permission, explicit Navigate, stale-fix expiry, hidden-map cancellation and secure-session gates remain intact.

Source review: backend main `da75415`, Flutter main `720b907`, October 25, 2026. The separate web branch adds current-stop route preview; publication/deployment is not established by this plan. Existing API and operational write gates remain authoritative.

Validation requires focused map/navigation and shared surface checks, Flutter analysis, normal Linux/Android builds and a scoped account of physical-device limitations. Record completed implementation evidence separately from this contract. The local map configuration is ignored and never included in source, command text or logs.

## Implementation and local evidence — October 25, 2026

Shared controls and cards now use standard 8px rounded rectangles, neutral boundaries and small neutral shadows. Dialogs/sheets use 12px corners; account imagery and duty controls retain their intentional circular shapes. Inputs keep visible resting borders, keyboard focus and high-contrast behavior; touch targets and reduced-motion support remain intact. Home starts with light street tiles; the dark toggle and cached native renderer remain available.

Road requests explicitly prefer avoiding ferries and request route details. The geometry parser rejects a returned ferry segment, excessive nesting, more than 100 sections or 10,000 points. Missing or unsupported routes remain failures rather than invented straight connectors. Existing explicit Navigate, fix accuracy/age requirements, cancellation and account/assignment gates remain in force. No new map dependency or browser renderer was added.

The final full Flutter test run passed **639 tests with five skips**. Focused theme/surface and map/navigation checks cover the changed shapes, light/dark defaults and ferry rejection. Flutter analysis found no issues. Both the Linux debug build and Android debug APK build passed using the existing ignored map configuration. The Android build emitted an SDK XML tooling-version warning; it still completed successfully. These tests do not establish physical Android GPS, camera, permission, background or performance acceptance.

Scoped interface consistency assessment: **7/10 to 8/10**, based on shared tokens, controls and responsive automated tests. Road-route validation improves within this slice; overall operational readiness is unchanged. Web route-preview publication and Azure configuration remain separate. No deployment, live parcel/cash action, account mutation or reference-project change was performed. No new local key was needed; existing ignored map configuration is retained. Task tracking remains pending because the existing login expired; no saved task or time update is claimed.
