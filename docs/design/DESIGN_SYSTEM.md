# Rider design system

These October 9 target tokens define the Rider app's independent modern mobile
presentation. Shared red branding and business behavior remain aligned with the
website; portal component styling does not govern this layout. Core target tokens now style existing app screens;
future views and optional candidates remain proposals, not accessibility claims. All sizing
uses native logical units, not copied CSS measurements.

## Color roles

| Role | Value | Why used |
|---|---|---|
| canvas | #F7F7FA | A quiet neutral background separates content from white inset groups. |
| surface | #FFFFFF | Opaque work/form/receipt background. |
| ink | #0F172A | Heading, destination and primary amount. |
| body | #1E293B | Readable address and instructions. |
| muted | #475569 | Supporting text that still has usable contrast. |
| accent | #E00D42 | One primary action, active navigation or meaningful current-task marker. |
| accent text | #C20836 | Small colored labels on rose need this stronger contrast. |
| accent pressed | #A1052B | Finite pressed state with a readable white label. |
| selection | #FFF2F4 | Selected task/choice without flooding the screen. |
| divider | #E2E8F0 | Quiet structural separation; not the only identifying boundary of a control. |
| control border | #64748B | Identifiable input/neutral button/choice boundary. |
| focus | #C20836 | Visible 2-unit or stronger focus outline with offset. |
| waiting surface | #FFF4DF | Relevant waiting/caution group. |
| waiting text | #92400E | Readable responsible actor/reason. |
| success surface | #ECFDF5 | Small server-confirmed result group. |
| success text | #047857 | Explicit recorded outcome, never decorative verification. |
| error surface | #FFF1F2 | Validation/rejection explanation, not every failed read as an alarm. |
| error text | #BE123C | Dark labelled error text and meaningful icon. |
| info surface | #EFF6FF | Useful informational group. |
| info text | #1D4ED8 | Readable information label. |

A status always has words and, where useful, an icon. Red is the brand action color; error is distinguished by wording and context. Neither red nor green universally creates urgency, trust or safety. White on the primary action is tested separately from red text on a tint.

## Calculated contrast

The solid-color proposal uses at least 4.5:1 for all normal text and 3:1 for required non-text control/state boundaries. Values below are calculated, not rounded pass thresholds. Actual opacity, imagery, font rendering, focus, disabled/read-only state and device brightness still require checks. [R06](SOURCE_REGISTER.md#r06), [R07](SOURCE_REGISTER.md#r07)

| Combination | Foreground | Background | Ratio | Required |
|---|---|---|---:|---:|
| White label on primary | #FFFFFF | #E00D42 | 4.877:1 | 4.5:1 |
| Small accent text on rose | #C20836 | #FFF2F4 | 5.695:1 | 4.5:1 |
| Heading on canvas | #0F172A | #F7F7FA | 16.696:1 | 4.5:1 |
| Body on surface | #1E293B | #FFFFFF | 14.629:1 | 4.5:1 |
| Secondary on canvas | #475569 | #F7F7FA | 7.087:1 | 4.5:1 |
| Control boundary on white | #64748B | #FFFFFF | 4.759:1 | 3:1 |
| Waiting text on sand | #92400E | #FFF4DF | 6.502:1 | 4.5:1 |
| Confirmed text on mint | #047857 | #ECFDF5 | 5.206:1 | 4.5:1 |
| Error text on pale rose | #BE123C | #FFF1F2 | 5.721:1 | 4.5:1 |
| Information text on pale blue | #1D4ED8 | #EFF6FF | 6.158:1 | 4.5:1 |
| Dark candidate heading | #F8FAFC | #111827 | 16.955:1 | 4.5:1 |
| Dark candidate supporting text | #CBD5E1 | #111827 | 11.948:1 | 4.5:1 |
| Dark candidate accent text | #FDA4AF | #3B1625 | 8.366:1 | 4.5:1 |
| Dark candidate boundary | #94A3B8 | #111827 | 6.919:1 | 3:1 |
| Dark candidate waiting | #FCD34D | #33220D | 10.589:1 | 4.5:1 |
| Dark candidate success | #6EE7B7 | #0A2E24 | 9.640:1 | 4.5:1 |
| Dark candidate error | #FDA4AF | #3F1723 | 8.177:1 | 4.5:1 |

**Do not use #E00D42 for normal small text on #FFF2F4: 4.473:1 is below 4.5:1.** Use the stronger accent text token. A selected marker can use the primary red where its required non-text contrast passes.

Dark colors are a complete candidate palette for the optional Appearance view, not an implemented theme. A dark media viewer can have its own functional stage without enabling whole-app dark mode. Do not ship the appearance switch until every actual component and state is checked.

## Border and surface decision table

| Element | Border/surface treatment | Why |
|---|---|---|
| Current task | White surface, subtle finite shadow or quiet outline, small current marker, explicit labelled action | Groups the work and supports hierarchy without turning every row into a box |
| Supporting information | Borderless content with a heading and enough spacing | Reading material needs relationships, not repeated control-looking outlines |
| Task/history/conversation row | Quiet separator and explicit text/chevron/focus state | Reduces clutter while remaining recognizable as a row action |
| Text field, select, radio choice | Visible control boundary; 12-unit corners | Users must recognize where input is possible; pale structural dividers alone are inadequate |
| Selected choice/slot | Rose tint plus radio/check/text and a clear selected marker | Selection stays understandable without color vision |
| Read-only managed facts | Definition rows, no input-shaped border | Visual appearance must not invite edits the rider cannot make |
| Waiting/exception instruction | One sand inset with dark reason and responsible actor | Highlights the useful next responsibility, without coloring the whole page |
| Recorded receipt | One small mint inset with outcome and time/reference | Confirms exactly what happened; it is not approval, buyer completion or payout |
| Map/media control | Opaque readable backplate and clear focus/target | Busy imagery must not hide the controls or labels |
| Overlay/dialog | One surface with visible title, close/cancel and bounded scrolling | Temporary layer groups one intent and restores context afterward |
| Sign-in/application | Restrained single form surface; clear field boundaries | Familiar task structure and readable labels take precedence over decorative depth |

Borderless is a grouping decision, not a requirement to remove focus or control identity. A fully clickable card needs a discoverable action and accessible semantics. A shadow is not sufficient as its only affordance.

## Type and spacing

Use the already bundled Plus Jakarta Sans throughout. Use aligned numeral features for amounts, not a second monospace/display family.

| Role | Size / line height / weight |
|---|---|
| page title | 24 / 32 / 600 |
| section | 18 / 26 / 600 |
| body | 16 / 24 / 400 |
| secondary | 14 / 20 / 500 |
| metadata | 13 / 18 / 500 |
| amount | 28 / 36 / 600 |

Sizes are starting tokens and scale with the device preference. Labels persist above input; placeholders supplement rather than replace them. Avoid all-caps prose, very thin text and truncating a destination's distinguishing words. At 200% text, content reflows rather than shrinking.

Use a 4/8/12/16/24/32 spacing rhythm. Compact page inset is 16; wider layouts use
24. Keep 8–12 within related content and 20–24 between groups. Grouped rows have
a 56-unit minimum height and full-row interaction; large text may increase it.

| Component | Target corner radius | Treatment |
|---|---:|---|
| Task/card surface and inset list group | 20 | Smooth outer contour; nested rows share the group, not separate boxes |
| Field and primary/secondary control | 12 | Clear focus/boundary and stable action shape |
| Saved-stop map/media frame | 16 | Bounded content with opaque controls |
| Dialog | 24 | One temporary intent with explicit dismissal |
| Bottom sheet upper corners | 28 | Soft contour, clear title and accessible close/action area |
| Navigation selection / compact tint | 12 | Restrained active marker; no decorative oversizing |
| Avatar, duty switch, dot / track | Circle or pill | Only where the control's meaning benefits |

Avoid a blanket radius applied to every element. Group surfaces remain opaque
white; thin neutral separators establish relationships. Decorative elevation is
small and consistent, while overlays alone receive enough depth to show layering.
These core shapes now apply to the existing app. The supplied brand-artwork tile
keeps its own contour; historical implementation records retain their original
measurements. Planned map/overlay views are not made functional by a shape token.

## Buttons and bottom geometry

- Primary: one filled accent action for the current permitted intent, 52-unit minimum height and full width on compact forms/work shelves.
- Secondary: neutral labelled control with a visible boundary, 48-unit minimum target. Directions, Call, Message and Retake are not competing saturated primary buttons.
- Tertiary: readable text action with a 48-unit standalone interaction region; inline links retain their text semantics.
- Destructive local action: explicit outcome wording and separation from Keep editing. It cannot cancel an assignment merely by dismissing a local draft.
- Disabled/unavailable: useful readable reason via O20 when appropriate; no hover-only tooltip, invisible hit target or guessed explanation.
- Measured bottom clearance equals the actual action shelf plus navigation plus safe inset. Keyboard-aware focus flows reserve the keyboard area and may use a shorter scrollable form.

The 48-unit target and 8-unit separation are Bagoo field-use choices. The web AA minimum criterion has a 24px rule with exceptions; it does not mean every target should be tiny. Native units, physical millimeters and CSS pixels are not interchangeable. [R08](SOURCE_REGISTER.md#r08)

## Map, diagram, photo, icon and chart treatment

- Map: one authorized saved stop initially, 240–288 units maximum compact task area when useful; expanded view still preserves address/actions. Keep attribution, visible failure/retry, opaque controls and address fallback. No moving dot or routed line without real accepted data.
- Parcel diagram: original simple motorcycle/bag layout, labelled compartments, selected radio/text; an equivalent list prevents a visual/drag-only interaction. The diagram never proves custody.
- Photos/proof: source/preview/replace/remove before submission; accepted private evidence is a read-only viewer. Imagery cannot obscure amount, control or recipient labels.
- Icons: one consistent outlined set, normally 20–24-unit visual size inside larger targets. Label unfamiliar operational actions. Decorative motifs are hidden from assistive technology.
- Charts: only returned data with scope/period, accessible summary and functioning filters. Prefer the work list before any chart; no guessed success rate, distance or income.

## Motion and feedback

Target finite timing: 120ms pressed feedback, 200ms navigation and 240ms sheet transitions. These are design timings, not measured performance claims. Use the device reduced-motion preference and an opaque alternative to any translucent navigation material. No infinite bouncing, loading delays added for appearance, racing countdown or continuous heavy blur. Reduced motion keeps immediate state feedback while removing nonessential displacement.

Pending state names the actual intent promptly. An upload selection, scan preview or spinner never becomes a successful handoff. Rejection points to the affected field; uncertain results reconcile before repeating an intent. A small result animation follows server acceptance only.

## Accessibility and device review

Use persistent labels, useful semantics, logical focus/reading order and announced validation/results. Focus remains visible above authored chrome; test 200% text and 320-width reflow. Support Back/Escape and return focus for overlays, without relying on a gesture alone. [R09](SOURCE_REGISTER.md#r09), [R10](SOURCE_REGISTER.md#r10)

Support password managers, code paste/autofill and native device permission prompts. Color, typography and target calculations are documented design evidence; they do not establish conformance or physical usability. [R11](SOURCE_REGISTER.md#r11)

The canonical numeric proposal is [tokens.json](tokens.json). Keep it in step with actual implementation and device findings rather than treating this palette as permanently correct.
