# Existing app mobile styling

Revised October 9, 2026 after review of the earlier flat/outlined presentation.
[The design specification](DESIGN_SPEC.md) now requires a tactile, layered style
on existing screens. Backend operations work remains separate.

## Runtime changes

- Ordinary fields and secondary controls have soft `#EEF0F4` fills and no dark
  outlines. Accent focus and error indicators remain visible; selected controls
  retain labels and explicit state. Primary red remains `#E00D42`.
- Native continuous superellipse contours replace circular corner geometry on
  shared groups, controls, dialogs and chrome: 24-unit groups/surfaces, 16-unit
  controls, 20-unit media, 28-unit dialogs and 32-unit sheets/navigation.
- Platform sans-serif typography replaces the bundled family as the first
  choice. The bundled font remains a fallback. Page titles use 28/34/700;
  secondary text has a quieter regular weight.
- Frosted header, floating dock and existing sheets use clipped 18-unit backdrop
  blur, translucent white fill and soft shadows. Opaque reading/field surfaces
  remain clear; neutral canvas shading establishes depth without accent artwork.
- Buttons and row actions gently compress and spring back. Gesture ownership,
  disabled guards, callback dispatch and hit/layout sizes stay with the existing
  controls. Workspace transitions preserve mounted tab state; account/approval changes
  remove private routes immediately, independent of decorative motion; scrolling uses
  momentum/elastic edges and existing sheets stay draggable with opaque reading bodies inside frosted shells.
- The dock reserves its actual safe-area footprint, including enlarged labels.
  High contrast, accessible navigation and reduced effects use opaque chrome;
  reduced motion also removes travel/scaling and uses clamped scrolling. Native
  motion flags are read where Flutter exposes them; no unsupported transparency
  preference detection is claimed.

Login, registration, holding, Home, Trips, Messages, Profile, Settings and their
existing forms share these primitives. This styling adds no routes or parcel
commands. Azure configuration, account restrictions, token storage, capability
checks, document uploads, code handling and private cleanup are preserved.
Synthetic repositories remain in tests.

## Review and evidence

Theme/token checks cover ordinary borderless fields, accent focus/error/high
contrast, native-family choices and continuous contours. Surface tests exercise
blur fallbacks, spring feedback, stable touch size, disabled actions and scroll
physics. Existing layout/navigation/account/Settings tests remain required.

Rendered review uses synthetic test data and real host sans-serif/Material icon
fonts under ignored `build/settings-ui` artifacts. Those images prove layout,
not live parcel integration or Android performance. Test taps fail on missed
hit targets, so floating chrome cannot silently hide controls during checks.

Fresh verification: **100 local tests passed**, with one expected explicit-
configuration skip; analysis is clean. Six existing-screen layout/render tests
passed again after the final neutral-fill refinement. Ordinary Linux and Android
debug builds passed; the APK retains its Azure origin and excludes retired
sample routes. Approval-loss cleanup is checked before animated settling.
Physical Android touch, keyboard, system preferences and performance still require
phone review; desktop renders do not establish those results.
