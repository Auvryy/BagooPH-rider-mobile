# Design research and reasoning

Reviewed October 6, 2026. Current platform guidance was fetched from its primary
pages or published machine-readable content. Classic behavioral findings are
kept with their boundary conditions; being old does not make a foundational
result obsolete, and being newly published does not make a visual trend useful.

The following are design hypotheses for this Rider workflow, not guarantees
or claims that an equation determines the number of screens.

| Principle | What it supports | Rider application | Limit |
|---|---|---|---|
| Jakob's Law | Familiar behavior reduces relearning | Stable four-destination navigation, Back, labelled forms, recognizable chat | A practitioner heuristic; preserve familiar interaction without copying another identity. [R12](SOURCE_REGISTER.md#r12) |
| Hick–Hyman choice timing | Choice structure can affect decision effort | One permitted primary action; meaningful task groups; staged evidence review | Laboratory choice timing is not a universal law that every extra menu item slows every real task. Do not hide critical cash/instructions. [R13](SOURCE_REGISTER.md#r13) |
| Fitts' Law | Target acquisition depends on movement and effective target geometry | Large spaced controls and nearby review/submit actions | No predicted milliseconds without device/task calibration; a large target in an awkward grip can remain difficult. [R13](SOURCE_REGISTER.md#r13) |
| von Restorff / distinctiveness | Distinctive items can affect memory in context | Reserve strong emphasis for the current responsibility or primary action | Memory isolation is not proof that a red button improves conversion or that perceptual salience alone explains every effect. [R14](SOURCE_REGISTER.md#r14) |
| Gestalt grouping | Spatial relations help organize information | Keep address/contact together, parcel/slot together and cash labels/values together | Containers are a practical layout application, not a rule to draw a border around everything. [R01](SOURCE_REGISTER.md#r01) |
| Recognition over recall | Visible context reduces what must be remembered | Full parcel identity, saved stop, phase and draft context remain available | Still protect contacts/evidence and remove unauthorized stale data. |
| Progressive disclosure | Secondary detail can be revealed on demand | Keep current stop/action first; expand history and optional explanation | Required evidence, cash due, errors and waiting actor are never hidden as decoration. [R01](SOURCE_REGISTER.md#r01) |
| Chunking and memory limits | Context affects what people can hold mentally | Readable groups and a short visible review summary | Neither seven nor four is a universal maximum for tabs/cards/pages; four tabs match four actual work areas. [R16](SOURCE_REGISTER.md#r16) |
| Feedback and visibility | People need to see request/outcome state | Distinguish sending, rejected, unconfirmed and server-recorded results | Animation and a local selection do not prove operational success. |
| Error prevention and recovery | Review and useful correction reduce avoidable mistakes | Match actual code before handoff; retain permitted drafts and point to field errors | Extra confirmation on every harmless action creates friction; reserve review for material intent. |
| Thumb reach | Hand/device geometry affects comfort and coverage | Symmetric large lower actions above insets, with familiar Back and gesture alternatives | A universal right-handed heat map is inadequate; the lowermost edge is not always comfortable. [R15](SOURCE_REGISTER.md#r15) |
| Semantic visual hierarchy | Meaning should determine emphasis | Neutral data, crimson action, rose selection, sand waiting, mint confirmed outcome | No universal psychological claim that a color guarantees trust, urgency or safety. |

## Current guidance translated to this app

Use available window dimensions, preserve context during resizing and separate
primary navigation from actions. The app-specific split threshold is selected
from content geometry, while current guidance provides reference classes and
adaptive patterns. [R03](SOURCE_REGISTER.md#r03), [R04](SOURCE_REGISTER.md#r04)

Separate functional navigation chrome from the data being read. The proposal
uses readable opaque work surfaces and restrained elevation; any transparency
has a strong fallback and does not surround every content card.
[R02](SOURCE_REGISTER.md#r02)

Keep device-safe placement, predictable labels and accessible supported
authentication. Verification-code paste/autofill and password managers remain
usable. A design must not introduce a memory puzzle as routine authentication.
[R01](SOURCE_REGISTER.md#r01), [R11](SOURCE_REGISTER.md#r11)

## Thumb-zone proposal to test

Frequent primary actions sit in the lower-central working area, above the
gesture/nav/keyboard boundary. This is a hypothesis about the target use,
not an empirically validated shape for every handset.

- Test left hand, right hand and two-handed use, short and long reach, large
  text and the intended physical devices.
- Keep action shelves symmetric; do not dynamically guess handedness or request
  a sensor permission merely for layout.
- Keep target centers away from cramped screen edges and ensure the complete
  interaction region fits above insets.
- Preserve non-gesture alternatives for map exploration, image zoom, selection
  and dismissal. No custody action is swipe/drag-only.
- Use the app while safely stopped. Large controls are not encouragement to
  operate a phone while riding.

The reach research examined particular phones and participants. We adopt the
need to account for geometry, not its percentages as a 2026 device prediction.
No glove/wet-screen performance claim is made without physical testing.

## How to evaluate the visual direction

Prefer readable hierarchy, consistent tokens and complete interaction states.
Beauty is judged with the intended riders and tasks. Test whether the current
stop and action are quickly identifiable, whether amounts are understood, and
whether help/recovery is discoverable. A tasteful image is evidence of a design
composition; it is not evidence that the operational flow is usable.

The [source register](SOURCE_REGISTER.md) distinguishes current guidance,
historical research, abstract-only evidence and product decisions. No trend,
law or platform example changes the parcel/financial contract.
