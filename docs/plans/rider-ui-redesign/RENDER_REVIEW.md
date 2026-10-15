# Runtime design review

Reviewed October 15–16, 2026. These are actual Flutter widget renders with
bundled Plus Jakarta Sans and Material icons, at a 390 × 844 logical viewport.
The logo is the existing Bagoo asset. All account, parcel and message content
shown here is synthetic; preview banners belong to the automated fixtures.
Ordinary app builds still use Azure login and do not expose these preview routes.

| Screen | Current runtime capture | Design decision |
|---|---|---|
| Sign in | [Login](screens/login-390.png) | Left-aligned brand, strong heading, quiet fields and one red primary action. |
| Registration | [Vehicle](screens/registration-vehicle-390.png) | Compact numbered steps and readable selection cards; step position does not imply completed validation. |
| Profile | [Profile](screens/profile-390.png) | Grouped work records, concise account identity and reserved navigation. |
| Conversation | [Thread](screens/conversation-390.png) | Distinct incoming/outgoing surfaces, visible parcel context and keyboard-aware composer. |

The October 9 storyboard remains historical proposal artwork. These current
captures and [the design specification](../../DESIGN_SPEC.md) guide future
implementation. The planned 48-view catalogue does not become implemented by
this review.

## Coverage and reproduction

The opt-in render test also captures all registration stages, verification,
holding, Trips and trip detail, Messages and restricted thread, every Profile
section, contact/password/email management, handover list/report/detail/recovery,
and private-evidence denial. Home/Stop Mode test suites generate additional
captures while checking selection, navigation and ordinary scrolling.

```sh
flutter test --no-pub test/redesign_visual_test.dart --dart-define=RIDER_VISUAL_REVIEW=true
flutter test --no-pub test/home_dashboard_test.dart test/home_overview_test.dart test/stop_mode_test.dart
```

Generated captures stay under ignored `build/redesign-verification/screens/`,
`build/home-overview-verification/` and `build/stop-mode-verification/`.
The four checked-in examples are copied directly from those synthetic renders.
If the host temporary directory is full, create an ignored build subdirectory
and set `TMPDIR` to it for the test command.

Functional/layout tests additionally cover 320–1440 logical widths, 200% text,
keyboard insets, unavailable/error/restricted data, stale commands, private route
cleanup and reduced motion. Home without map configuration shows a compact
address fallback, with enough space for its explanation at large text. Configured
maps retain provider tiles, actual pins, route geometry and attribution.

Desktop captures and builds do not verify physical Android touch, GPS, camera,
notification or background behavior. This presentation change does not clear
remaining live API or device acceptance gates. Existing exact-value, authorization,
replay and custody rules remain covered by their functional tests.
