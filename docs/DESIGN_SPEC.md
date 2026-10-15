# Rider frontend design specification

Reviewed **October 15, 2026**. The current visual direction is a delivery-focused
mobile interface: clear headings, compact work cards, a useful map and calm white
surfaces. It supersedes the October 9 frosted-chrome/system-font direction.
The [redesign plan](plans/rider-ui-redesign/README.md) records implementation and
verification of every existing page. The wider counted catalogue remains a
proposal; visual work does not implement its missing APIs or workflows.

## Design direction

The three user-selected delivery/ride references inform composition, not copied
artwork: a compact identity header, bold readable titles, grouped work summaries,
map emphasis and one clear next action. Adapt these patterns to Bagoo's existing
logo and **red `#E00D42`**. Keep status colors semantic and labelled.

1. **Clear hierarchy.** A screen has one leading title and one primary action.
   Short contextual labels, strong values and restrained icons help scanning.
   Avoid repeated identity cards, nested boxes and paragraphs above routine tasks.
2. **Quiet surfaces.** Use opaque white cards on `#F7F7FA`, soft neutral fields,
   fine separators and minimal elevation. Navigation and overlays use solid white,
   without blur, gradients or glass. Red marks actions and selected responsibility.
3. **Consistent typography.** Use the bundled Plus Jakarta Sans throughout all
   platforms. Headings are confident, body text stays comfortably readable, and
   monetary values retain their exact server formatting. Do not shrink large text.
4. **Predictable movement.** Reserve bottom navigation space; do not float it
   over content. Home is an ordinary scrolling page, never a draggable sheet.
   Temporary sheets retain explicit dismissal. Press feedback, focus, Back,
   keyboard clearance and reduced-motion behavior remain available.

Small accent text uses `#C20836`. Resting fields use `#EEF0F4`. Continuous
contours use **20-unit surfaces/groups, 14-unit controls/selection, 20-unit maps,
28-unit dialogs/sheets**. The bottom navigation has a straight edge and subtle
divider; its selected item has a soft red fill. The original logo is unchanged.
The canonical values live in [tokens.json](design/tokens.json).

The mobile app shares the website's business meanings, data, branding and
permissions. It owns its own presentation: do not copy portal CSS, desktop
panels, uniform corner geometry, breakpoints or long information stacks.
Website source remains the authority for approval, assignment, custody and cash;
its visual style is not the mobile layout specification.

Keep all design prose, example UI and artwork vendor-neutral. Describe the
native mobile patterns and behavior directly, without naming a reference handset
or claiming compatibility with a proprietary visual material. Verified source
URLs can remain in the neutral source register for research traceability.

The selected experience stays **Stop Mode + Parcel Finder + Doorstep Guide**.
The rider must see the current responsibility, authorized stop and clear action
before decoration. Group everyday choices into short labelled rows. Reveal
account/vehicle records, identity guidance and operation-specific fields only
when needed; this does not hide essential task or safety information.

Navigation, addresses, amounts, fields and task content are opaque in every
mode. The rationale is recorded in
[RESEARCH_AND_RATIONALE.md](design/RESEARCH_AND_RATIONALE.md).

## Mobile composition rules

- Use a compact, legible header and one clear page title. Avoid repeating the
  same brand, identity, status and explanation in several panels on one screen.
- Prefer white inset list groups with thin neutral separators, labelled icons,
  complete-row targets and consistent disclosure indicators. Groups share a
  relationship; cards are reserved for a bounded task or selected responsibility.
- Put common actions within the first normal-size phone viewport. Longer managed
  records open through named rows. Preserve full readable values and vertical
  reflow at large text instead of shrinking labels or hiding controls.
- A short form starts with the editable fields and its action. Password, code and
  other sensitive inputs appear only for the chosen operation. Rare guidance can
  expand in place; avoid an extra page containing only one navigation button.
- Keep the four labelled destinations stable. A restrained continuous selection
  shape and small accent are enough; navigation is distinct from content, reserves its measured safe footprint and
  never covers the main action, keyboard, system gesture area or focused field.
- Sheets use a clear title, explicit dismissal and visible intent, with a soft
  upper contour. Use finite transitions that preserve origin and focus; provide
  reduced-motion behavior. Do not add blur or animation to evidence
  that must remain readable.
- Use shape, hierarchy and whitespace for polish while preserving 48-unit touch
  targets, 56-unit grouped rows, labelled feedback and the actual server state.

## Read the design in this order

| Document | What it answers |
|---|---|
| [DESIGN_SYSTEM.md](design/DESIGN_SYSTEM.md) | Color meaning, measured contrast, type, spacing, cards, borders, controls and motion |
| [SCREEN_INVENTORY.md](design/SCREEN_INVENTORY.md) | Exact theoretical counts, every view/overlay/state and coverage |
| [PAGE_BLUEPRINTS.md](design/PAGE_BLUEPRINTS.md) | Composition, navigation, button placement, color/borders, responsiveness and recovery for every page |
| [RESEARCH_AND_RATIONALE.md](design/RESEARCH_AND_RATIONALE.md) | Jakob, Hick, Fitts, von Restorff, grouping, memory and thumb-reach application with limits |
| [IMPROVED_DESIGN_BRIEF.md](design/IMPROVED_DESIGN_BRIEF.md) | Review requirements for the mobile visual direction and honest implementation status |
| [Historical storyboard](design/visuals/storyboard.png) | Eight October 9 proposal compositions; superseded styling, not app screenshots |
| [SOURCE_REGISTER.md](design/SOURCE_REGISTER.md) | Dated evidence and original references |

## Theoretical page count

The counted design has **48 native full views**, comprising **38 baseline**,
**3 selected**, **2 conditional** and **5 optional** views. It also includes
**8 first-party web entry views/panels**, **20 app overlays**, **3 device-owned
surfaces**, **15 shared states** and **8 Stop Mode stage variants**.

All 40 earlier ideas have a mapping. Twelve unselected future concepts are
specified separately: five full views, five sheets and two components. Choosing
every future full view would expand the theoretical native pool to **53**.
That is a coverage calculation, not a promise to implement 53 routes.

A full-screen form step counts as a designed view even if implementation uses
one route for several steps. A filter change, empty result or pickup/delivery
variant does not automatically become another page. This prevents inflated
counts and still records every user-visible situation. The
[inventory](design/SCREEN_INVENTORY.md) is canonical for these distinctions.

## Information architecture

Primary destinations stay **Tasks, Trips, Messages, Profile**, in that order.
Home is the Tasks overview; it is not an extra fifth tab. Settings is under
Profile. Activity opens from a labelled bell/entry; cash and earnings open
through Profile or their relevant records when supported.

```mermaid
flowchart TD
    A[Sign in] --> G[Fresh account and capability check]
    G --> H[Holding or authorized recovery]
    G --> T[Tasks]
    T <--> R[Trips]
    T <--> M[Messages]
    T <--> P[Profile]
    T --> S[Stop Mode]
    S --> F[Parcel Finder]
    S --> D[Doorstep Guide and saved-stop map]
    S --> E[Scan and evidence focus workflow]
    E --> C[Recorded receipt]
    S --> X[Failure and return responsibility]
    R --> J[Trip detail and authorized proof]
    M --> Q[Parcel-linked thread]
    P --> K[Settings, security and help]
    P --> N[Cash responsibility and confirmed earnings]
    T --> I[Activity inbox]
    A --> W[First-party web application or recovery]
```

Tabs are destinations, not actions. Duty, Scan, Record delivery and Sign out
never become tabs. Tab order and labels stay stable through empty/error states.
Holding screens do not expose operational navigation without permission.

Read/detail pages retain their parent tab selection. Back restores the actual
origin, selection and scroll. Camera, proof forms and other temporary focus
flows may cover navigation as a full-screen modal workflow, then restore it.
This is a deliberate focus presentation, not randomly disappearing tabs.
The conversation composer must sit above the keyboard with a visible return
to its list.

## Responsive layout proposal

Use **available layout width and height**, not the device model or orientation
name. These thresholds are product proposals, informed by current adaptive
guidance; they are not universal standards or copied web breakpoints.

| Available native width | Navigation and composition |
|---|---|
| 320–599 logical units | Four labelled bottom destinations; one-column task/read/form layout; 16-unit page margins |
| 600–959 | 80-unit navigation rail when usable; a centered single work/reading column; 24-unit margins |
| 960 and above | Rail plus a 300-unit master list and at least 420-unit detail area where meaningful; 24-unit gap; cap overall content width |
| Short height or 200% text | Prefer one readable pane; collapse decorative headers and map area before shrinking type or touch targets |
| Folded/split window | Recompute from actual safe available bounds; no essential control across a hinge or cutout |

The wide pairing needs room for rail, margins, gap, list and detail:
80 + 48 + 24 + 300 + 420 = **872 units**. The 960 threshold gives additional
space and avoids a cramped two-pane form. This is a design choice to verify
on target devices. The existing web portal's 1280px desktop shell is a
separate implementation; this document does not restyle that project.

Keep forms at 560 units maximum and long reading around 680. Keep address and
amount relationships intact at large text. At 320, wrap chips, stack secondary
actions and use full-width primary actions. Horizontal scrolling is for the
map/image content when appropriate, not required form or task controls.

## Thumb reach, action placement and keyboard

Place the frequent primary task action in a lower shelf **above** navigation
and safe-area/gesture insets. A bottom bar is not automatically reachable for
every thumb: hand size, grip, device width and the lowermost edge all matter.

Use 48-unit minimum standalone targets, 52-unit primary actions and 8-unit
minimum separation as the Rider field-use proposal. Keep full-width actions
symmetric so they work for both hands. Back/help retains a familiar top location
and a large target; common task actions should not require repeatedly reaching
the far top corner.

Choose one bottom arrangement per view. Measure the actual action shelf,
navigation and keyboard insets; reserve their complete combined footprint in
scrollable content. Do not stack a floating button, tab bar, sheet and keyboard
over the same controls. Modal forms keep their action reachable without hiding
the focused field. Test both hands and a two-handed grip while stopped.

## How Home should look

The implemented phone Home is map-first: compact identity and duty → bounded
map and attribution → map controls/status → hub, eligibility and refresh →
counted queue tabs and task cards. The page scrolls normally. Short windows omit
the map and keep all work controls reachable; large text reduces the map height.
Wide windows place the queue beside the map. Bottom navigation reserves space.

The selected task uses a white surface with its full destination, parcel identity
and Open Stop Mode action. Queue cards use white, with soft rose selection.
Counts come from the server; an unavailable count is never invented as zero.
Missing coordinates retain the address. No destination or route is guessed.

The [Home/navigation implementation](plans/home-dashboard-navigation/README.md)
and [redesign coverage](plans/rider-ui-redesign/README.md) describe current runtime
behavior. [P05](design/PAGE_BLUEPRINTS.md#p05) remains a broader future blueprint;
it does not override this implemented map-first extension.

## Selected feature compositions

| Experience | Visual structure and reason |
|---|---|
| Stop Mode | Stage/parcel → full destination → instruction excerpt → bounded map → parcel position/cash → next action. Group related facts; one action attracts attention. |
| Parcel Finder | Owned parcel list → small labelled bag diagram → selected slot → Set/Clear. The diagram supports recognition and stays supplementary to identity/scanning. |
| Doorstep Guide | Original destination → entrance/landmark → unit/access details → directions/contact fallback. Plain readable sections beat decorative cards around each sentence. |

The saved target is labelled. The accepted Home/navigation extension draws
provider road geometry and an explicitly started location marker; Linux uses
a labelled manual origin. Multi-stop optimization, spoken directions inside
Rider and automatic arrival/outcomes remain outside this scope.
Tile failure preserves the address and actions. Zoom/Show stop controls have
large labelled touch targets and opaque backplates. Attribution stays visible.

## Visual decisions that should be consistent

- Use filled crimson for one meaningful primary action, light rose for selection,
  sand for relevant waiting and mint for a recorded result. Pair every state
  color with text/icon.
- Use borderless information groups when spacing, headings and dividers are
  enough. Use filled, labelled inputs/choices and borderless neutral buttons; focus and
  explicit errors/selected choices use accent indicators.
  Read-only managed values are definition rows, not disabled-looking inputs.
- A task card can use a subtle shadow and continuous contour because its nested explicit action
  is discoverable. A fully clickable row needs text/chevron, focus and semantics.
  A shadow alone does not identify a control.
- Align labels and values predictably; use one typeface and a compact type scale.
  Cash amounts use aligned numerals, not a separate decorative font.
- Use small original vector motifs only in empty/intro/profile contexts.
  Camera, proof, address and financial information get functional emphasis.
- Motion explains selection, sheet placement or accepted feedback. It is finite,
  lightweight and removed/reduced under the device preference.

The exact tokens, combinations and border decision table are in the design
system. Each blueprint gives its own color/border reason.

## Visual layout studies

See [current runtime captures](plans/rider-ui-redesign/RENDER_REVIEW.md) for the
implemented October 15–16 design.

![Adaptive composition sketches](design/visuals/adaptive-layouts.png)

![Both-handed action placement proposal](design/visuals/action-placement.png)

These are historical October 9 documentation sketches, not current runtime
screenshots or rendered layout/device checks. The October 15 redesign and
[render-review instructions](plans/rider-ui-redesign/README.md) supersede their
old visual treatment.
They illustrate content-driven adaptation and inset-aware action placement.

## Operational meanings the design must preserve

Seller pickups are rider-claimed; final-mile delivery is hub-assigned.
An assignment is not a physical handoff. The current web model supports up
to five active pickups and disallows a new final-mile assignment while other
active courier work remains. Design does not turn that into a multi-parcel
final-mile run or universal exact-barangay assignment.

Use the current stage's authorized stop. Origin-hub intake, failed return receipt
and reconciliation belong to their actual actors. Delivery receipt is different
from buyer completion and cash remittance. Missing ledger data is unavailable,
not zero. An illustration, code lookup or photo selection is not proof.

The [operational flow](RIDER_FLOW.md) and
[selected feature plan](FEATURE_DIRECTION.md) remain the source for actions.
This design does not add a new operational endpoint or change custody.

## What the original request was missing

The improved brief explicitly covers navigation restoration, recovery states,
keyboard and safe areas, large text, both-handed use, low light/sunlight,
map-data honesty, private evidence, unknown permissions, empty history,
actual amount meaning, translation, optional-scope labels, motion reduction,
design-to-code tokens and a meaningful usability review.

## Validation before calling the design successful

Use documentation checks now and actual prototype/device checks during the
selected implementation task. Suggested review tasks: claim a pickup, find a
tagged parcel, understand hub waiting, inspect entrance instructions, record
a handoff, recover a rejected photo, handle a failed delivery, read a message
with the keyboard and distinguish cash held from earnings.

Measure completion/error/recovery and observe reach; do not assert time savings
or universal superiority from a law name or an attractive picture. Verify at
320/360/390/430 units, tablet/wide bounds, landscape short height, 200% text,
keyboard open, screen reader, reduced motion and adverse network states.

All 16 major areas and earlier 40 ideas have documented mappings. Current
source reads, calculated contrast and static illustrations establish a
reviewable specification, not native usability, deployed APIs or release
readiness. Implementation estimates and the November freeze remain separate.
