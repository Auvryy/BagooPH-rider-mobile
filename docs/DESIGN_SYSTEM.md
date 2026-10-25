# BagooPH Rider Mobile — Design System

> **Standard:** Top-Tier Minimalist Digital Craft (Linear / Stripe / Apple Design Award Benchmark)  
> **Brand Principle:** "One Red" Strict Monochrome + Crimson Foundation  
> **Target Platform:** Flutter (Android & Linux Desktop Workstation)  
> **Typography:** Plus Jakarta Sans with Tabular Figures

---

## 1. Visual Foundation: The "One Red" Rule

Visual noise, unnecessary gradients, and multi-colored rainbow tags are eliminated. The entire application is built on a high-contrast, razor-sharp neutral foundation where **Crimson Red (`#E00D42`)** is the single, unmistakable hero color.

### 1.1. Color Tokens

| Token | Value | Hex / RGBA | Role & Application |
|---|---|---|---|
| `brandPrimary` | Crimson Red | `#E00D42` | **The ONLY Accent Color.** Reserved for primary CTAs, active selection indicators, live badges, and focus rings. Never floods full backgrounds. |
| `brandSubtle` | Soft Red Tint | `rgba(224, 13, 66, 0.08)` | Active pill backgrounds, subtle notification pings, focused chip fills. |
| `brandGlow` | Legacy selection tint | `rgba(224, 13, 66, 0.16)` | Shared surfaces use neutral elevation; indicate selection with a border and label. |
| `canvasBackground` | Neutral White | `#FAFAFA` | App-wide background canvas behind all views. |
| `surfaceCard` | Crisp Pure White | `#FFFFFF` | Primary cards, sheets, modal sheets, and floating surface panels. |
| `surfaceCarbon` | Deep Carbon | `#090A0F` | High-contrast banners, terminal notices, and deep pill controls. |
| `textPrimary` | Deep Ink | `#18181B` | Primary headlines, waybill IDs, customer names, and action titles. |
| `textSecondary` | Balanced Slate | `#62626B` | Supporting labels, addresses, timestamps, and secondary captions. |
| `textMuted` | Muted Gray | `#94A3B8` | Placeholders, disabled states, and inactive tab icons. |
| `borderQuiet` | Whisper Slate | `#DEDEE3` | Subtle 1px structural borders dividing cards and lists. |
| `borderSubtle` | Ink Tint Border | `rgba(17, 24, 39, 0.07)` | Translucent edge borders on floating overlays and elevated pills. |

---

## 2. Core Aesthetic Philosophy

### 2.1. Effortless Minimalism
- **Functional Subtraction:** If an icon, box, or badge does not directly help the courier navigate to the stop, scan the waybill, or verify COD, it is removed.
- **Whitespace as Structure:** Generous whitespace, razor-sharp alignment, and typography hierarchy separate content without resorting to thick dividers or heavy container fills.

### 2.2. Layered Depth (No Muddy Shadows)
Heavy, dark drop shadows are strictly prohibited. Depth is achieved through three deliberate optical layers:
1. **Whisper-Quiet 1px Borders:** `1.0px` solid borders (`#DEDEE3` or `rgba(17, 24, 39, 0.07)`) defining clear, tactile edges.
2. **Soft Ambient Elevation:** `BoxShadow(color: Color(0x0D18181B), blurRadius: 3, offset: Offset(0, 1))` providing natural floating separation.
3. **Solid Chrome:** white navigation and opaque readable map controls preserve contrast without background blur.

### 2.3. Precision Typography
- **Typeface:** Bundled **Plus Jakarta Sans** geometric sans-serif stack.
- **Editorial Headings:** Tight letter-spacing (`-0.02em` or `-0.5px`) on bold headlines (`w700`/`w800`) for commanding clarity.
- **UI Controls:** Crisp medium weights (`w500`/`w600`) with neutral letter-spacing for buttons, form labels, and chips.
- **Tabular Numbers (`tabular-nums`):** All timers, order IDs, waybill barcodes, COD currency amounts, and phone numbers use font feature settings `['tnum']` so digits align with Swiss watch precision across list rows.

### 2.4. Strict 4px/8px Spacing Grid
Every margin, padding, spacing, and height adheres strictly to the `4px`/`8px` scale:
- `4px` (`xxs`): Badge micro-padding, icon gaps.
- `8px` (`xs`): Chip spacing, inline text-to-icon gaps.
- `12px` (`sm`): Compact card padding, field gap.
- `16px` (`md`): Standard card inner padding, list item gaps.
- `24px` (`lg`): Screen edge margins, section spacing.
- `32px` (`xl`): Major module separation, header vertical margins.

**Border Radii Scale:**
- `8px`: Standard rounded cards, inputs, buttons, media and selected controls.
- `12px`: Dialogs and sheets.
- `999px`: Circular status indicators, avatars and the existing navigation capsule.

Use a neutral `#FAFAFA` canvas, white surfaces, `#18181B` text and `#DEDEE3` boundaries with Bagoo's `#E00D42` accent. Shared controls follow the compact card, field and separator hierarchy associated with shadcn; Flutter keeps native widgets and existing accessibility. Standard rounded rectangles replace the larger continuous contours. Use subtle neutral elevation instead of coloured glows. The Home map starts in daylight street style, with dark mode available through its existing explicit style control. Real road geometry, attribution, lifecycle cancellation and permission rules remain intact.

---

## 3. Tactile Micro-Interactions & Motion Engine

Every touch and state change in BagooPH Rider Mobile feels physical, rapid, and natural:

### 3.1. Spring Deceleration
- Standard Motion Easing: `Cubic(0.16, 1.0, 0.3, 1.0)` for natural physical deceleration without robotic linear motion.
- Fast Feedback Duration: `150ms` – `220ms` for tap scale, hover, and focus responses.
- Modal & Sheet Reveal: `300ms` – `400ms` with fluid entry curves.

### 3.2. Tactile Press Feedback
- All interactive controls (buttons, work cards, navigation tabs) scale down subtly to `0.98` on touch-down (`transform: Matrix4.diagonal3Values(0.98, 0.98, 1.0)`) and spring back on release.
- Accompanied by finite haptic spring response and immediate visual focus without sluggish animation delays.

### 3.3. 60fps / 120fps GPU Rendering Guard
- Only animate `transform` (scale, translate) and `opacity`.
- Never animate layout geometry (`width`, `height`, `margin`, `padding`, `top`, `bottom`) that triggers costly layout recalculations or causes frame drops.
- Always respect `MediaQuery.disableAnimationsOf(context)` or `RiderMotion.reduced(context)` with instant, clean static rendering.

### 3.4. The 6 Polished Component States
Every interactive component explicitly handles:
1. **Idle:** Pristine white surface, quiet 1px border `#DEDEE3`, deep ink label.
2. **Hover (Desktop / Mouse):** Subtle background illumination (`#F8FAFC`), crisp border sharpening.
3. **Active / Pressed:** Physical `scale(0.98)` spring compression, subtle highlight.
4. **Focus-Visible:** Razor-sharp Crimson (`#E00D42`) `2px` focus ring with `2px` offset.
5. **Loading:** Monochromatic shimmer skeleton (`#F1F5F9` to `#DEDEE3`), never an unstyled "Loading..." text string.
6. **Empty:** Clean illustration or centered icon with slate caption and one clear primary CTA.

## 4. Geographic display

The [street-map refinement](plans/rider-street-map/README.md) defaults Home to
light street tiles and neutral controls. The earlier
[map refinement](plans/rider-map-refinement/README.md) remains the lifecycle
foundation; its `RiderMapColors` tokens still support the dark option through
an explicit toggle. The PH display footprint and provider credits
remain visible; country framing never represents service eligibility.

Use one outlined crimson-family road line, small white/red stop pins and a
distinct ringed position dot. State comes from labels/icons as well as color.
No green/amber/red pavement-condition legend or road condition is fabricated.
Map buttons retain 48dp targets and stable bounds; selection animates scale only,
with reduced motion respected. High-density displays request native 2x artwork
through the existing bounded provider scheduler.
The labelled Save data control offers standard tiles while preserving this
palette, route and camera. Loading and persistent basemap behavior belong to the
[map loading extension](plans/map-loading-performance/README.md).

Frame the rider area from an accepted foreground GPS snapshot, or from an
explicitly labelled manual Linux origin. A snapshot is not live navigation;
continuous route-following starts only after Navigate. Keep normal scrolling,
address-first tasks and map-failure recovery. The complete technical boundaries
and acceptance evidence belong to the linked package.
