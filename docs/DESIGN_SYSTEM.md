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
| `brandGlow` | Crimson Ambience | `rgba(224, 13, 66, 0.16)` | Controlled glow rings and spring selection indicators. |
| `canvasBackground` | Light Slate | `#F8FAFC` | App-wide background canvas behind all views. |
| `surfaceCard` | Crisp Pure White | `#FFFFFF` | Primary cards, sheets, modal sheets, and floating surface panels. |
| `surfaceCarbon` | Deep Carbon | `#090A0F` | High-contrast banners, terminal notices, and deep pill controls. |
| `textPrimary` | Deep Ink | `#111827` | Primary headlines, waybill IDs, customer names, and action titles. |
| `textSecondary` | Balanced Slate | `#64748B` | Supporting labels, addresses, timestamps, and secondary captions. |
| `textMuted` | Muted Gray | `#94A3B8` | Placeholders, disabled states, and inactive tab icons. |
| `borderQuiet` | Whisper Slate | `#E2E8F0` | Subtle 1px structural borders dividing cards and lists. |
| `borderSubtle` | Ink Tint Border | `rgba(17, 24, 39, 0.07)` | Translucent edge borders on floating overlays and elevated pills. |

---

## 2. Core Aesthetic Philosophy

### 2.1. Effortless Minimalism
- **Functional Subtraction:** If an icon, box, or badge does not directly help the courier navigate to the stop, scan the waybill, or verify COD, it is removed.
- **Whitespace as Structure:** Generous whitespace, razor-sharp alignment, and typography hierarchy separate content without resorting to thick dividers or heavy container fills.

### 2.2. Layered Depth (No Muddy Shadows)
Heavy, dark drop shadows are strictly prohibited. Depth is achieved through three deliberate optical layers:
1. **Whisper-Quiet 1px Borders:** `1.0px` solid borders (`#E2E8F0` or `rgba(17, 24, 39, 0.07)`) defining clear, tactile edges.
2. **Soft Ambient Elevation:** `BoxShadow(color: Color(0x0D111827), blurRadius: 20, offset: Offset(0, 4), spreadRadius: -2)` providing natural floating separation.
3. **Frosted Glass Overlays:** `BackdropFilter` with Gaussian blur sigma `12.0` and translucent white fill `rgba(255, 255, 255, 0.85)` for floating navigation bars, modal headers, and map controls.

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
- `12px`: Form input fields, buttons, interactive chips.
- `16px`: Standard work cards, task containers, stop details.
- `20px`: Floating sheets, bottom sheets, large dashboard panels.
- `999px`: Fully circular pill buttons, status indicators, navigation tabs.

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
1. **Idle:** Pristine white surface, quiet 1px border `#E2E8F0`, deep ink label.
2. **Hover (Desktop / Mouse):** Subtle background illumination (`#F8FAFC`), crisp border sharpening.
3. **Active / Pressed:** Physical `scale(0.98)` spring compression, subtle highlight.
4. **Focus-Visible:** Razor-sharp Crimson (`#E00D42`) `2px` focus ring with `2px` offset.
5. **Loading:** Monochromatic shimmer skeleton (`#F1F5F9` to `#E2E8F0`), never an unstyled "Loading..." text string.
6. **Empty:** Clean illustration or centered icon with slate caption and one clear primary CTA.
