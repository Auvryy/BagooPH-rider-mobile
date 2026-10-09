# Existing app mobile styling

Implemented October 9, 2026 from the neutral/red visual target in
[the design specification](DESIGN_SPEC.md). Only existing UI is styled; the
backend's new native operations work is separate and was read only.

## Runtime changes

- Neutral `#F7F7FA` canvas with primary `#E00D42` retained and bundled typeface.
- White 20-unit cards/inset groups, 12-unit fields/controls/selection, 16-unit
  media frames, 24-unit dialogs and 28-unit sheet corners. Supplied brand artwork
  keeps its own contour rather than clipping it into another surface shape.
- Rounded inset bottom navigation, quiet app bars and neutral dividers. Existing
  labels, Back hierarchy, safe areas and minimum control sizes remain intact.
- Home filters use a compact grouped row at normal phone width, with full queue
  names exposed to semantics and a wrapping layout at small/large-text sizes.
- Entry, registration, holding, workspace states, list/detail surfaces, chat,
  Profile/Settings and account forms share the same theme. Future screens, data
  adapters, operational commands and dark candidates are not added by styling.
- Finite navigation/selection/sheet motion respects reduced-effects preferences.
  Data remains opaque; no decorative blur, fake success or artificial delay is
  introduced.

Azure defaults, real-account behavior, token storage, ownership/capability checks,
registration uploads, email codes and private cleanup are unchanged. Test-only
repositories stay in tests; no sample page is exposed in the ordinary app.

## Review and evidence

`test/app_theme_test.dart` checks the runtime colors/shapes against the canonical
JSON tokens, control sizes and reduced-effects behavior. Existing navigation,
account, Settings, large-text and keyboard tests still run. Render review covers
existing entry/registration and workspace screens under ignored `build/settings-ui`
with synthetic test data. Those images are layout evidence, not live operations.

The ordinary app remains connected to Azure even when a desktop layout frame is
enabled. A physical-phone review should cover touch, Back, text scaling, keyboard
and runtime transitions; desktop tests do not establish those device results.

Final verification: analysis clean; 89 local Flutter tests passed, including
canonical token/control checks, reduced-effects scenarios and existing screen
renders. Ordinary Linux and debug Android builds passed. APK origin/sample-route
checks passed. No phone was connected, so physical touch/keyboard/system-motion
review remains unverified; no live account mutation occurred.
