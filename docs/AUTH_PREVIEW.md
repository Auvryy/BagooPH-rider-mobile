# Login and registration design preview

Implemented October 6, 2026 as a presentation-only slice requested before API
integration. Start with [the root run instructions](../README.md#run-locally).

## Open and explore

Run `flutter run -d linux` for the debug phone frame, or
`flutter run -d chrome --dart-define=DEVICE_PREVIEW=false` for the responsive
browser layout. The browser hash routes are `/#/login` and `/#/register`.

- Login opens first. **Apply as a rider** opens registration.
- Registration has **Your details**, **Vehicle** and **Documents** steps.
  Tap a step directly or use **Continue** and **Back**. Empty fields do not
  prevent exploring the screens. Changing steps returns the viewport to the top.
- **Back to sign in** or the lower **Sign in** link returns to login.
- Password visibility, the birthday picker, vehicle selection and local field
  feedback work. Remember-email selection lasts only while this login view lives;
  it does not save an email or session.
- Document selection uses the platform picker. Only the filename is retained in
  memory, across step changes. Cancel, replace, remove and the 5 MB size check
  work locally. No file is uploaded, copied into app storage or persisted.
- Sign-in, recovery and application submission show explicit preview messages.
  They do not claim account creation, approval, delivery access or email delivery.

## Design and source alignment

The slice follows [P01 and E01–E03](design/PAGE_BLUEPRINTS.md), adapted to a native
registration preview at the user's request. The live onboarding recommendation
remains first-party web until a separate API scope is accepted.

Colors and geometry follow [the design system](design/DESIGN_SYSTEM.md):
`#E00D42` primary, `#FFFAFB` canvas, `#C20836` small accent text on rose,
`#64748B` control boundaries, 8-unit corners, 48-unit secondary controls and
52-unit primary actions. Labels persist above fields. Compact layouts use one
scrolling column; wide layouts add a brand introduction. At large text the form
stays in one column and step/action groups reflow. No operational tabs appear.

The mark in `assets/branding/bagoo-mark.svg` is extracted from the backend's
`resources/js/Components/BagooLogo.tsx`, with SVG attribute names normalized.
`bagoo-mark.png` is its 512px raster export, bundled for Flutter rendering.
This is the existing Bagoo mark, not a replacement identity.

Plus Jakarta Sans is bundled as a variable font in
`assets/fonts/PlusJakartaSans.ttf`. Its SIL Open Font License is included in
`assets/fonts/OFL.txt` and registered with Flutter's license registry. Source:
[Google Fonts distribution](https://github.com/google/fonts/tree/main/ofl/plusjakartasans)
and [the font maintainer](https://github.com/tokotype/PlusJakartaSans).

The local backend source reviewed for this slice was
`3a3d64a636bdc5534ec9fd6bbf5a34aaa4c520c5`. Its Bagoo logo, courier registration
view, application validation service and registration controller supplied the
three-stage structure, Motorcycle / Scooter / Sedan / Van choices, adult birthday
policy and document formats/size. This is source inspection, not deployment or
native-API acceptance. Address fields remain free text in the preview; live
location selectors and authoritative validation need agreed resources.

`file_selector` 1.1.0 provides the local picker with Linux, web and Android support
under BSD-3-Clause. Extension, MIME and Apple type filters are provided. Android
support starts at SDK 21; native device behavior has not been verified here.
See [the package documentation](https://pub.dev/packages/file_selector).

## Verification and limits

`test/auth_preview_test.dart` exercises navigation, local sign-in feedback,
password visibility, registration step/draft behavior, local document selection,
cancellation, size rejection and removal. It loads the bundled font and checks
both pages and all registration stages at widths 320, 390, 430, 768 and 1440,
normal/200% text, safe-area padding and simulated keyboard insets. Primary
actions must remain scroll-reachable above the keyboard.

Run `flutter analyze`, `flutter test`, `flutter build linux --debug`, and
`flutter build web --no-web-resources-cdn` to repeat the automated/build checks.
All four checks passed on October 6, including all 14 widget tests. Fresh browser
visits to both routes were rendered and reviewed at 390px and 1440px, with real
pointer interaction for the Vehicle, Documents and Back controls. No browser
runtime exception or external resource request occurred. These checks do not
establish physical Android behavior or full accessibility conformance.

No backend request, secure token adapter, approval state, email challenge or
operational fixture is included. M02 and M03 backlog cards retain their existing
planned status because their complete outcomes and dependencies are larger than
this UI slice.
