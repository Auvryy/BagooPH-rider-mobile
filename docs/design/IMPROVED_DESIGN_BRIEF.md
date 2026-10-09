# Mobile design review requirements

This is a technical review checklist for the Rider visual system, not a copyable
agent prompt. Keep external handoff prompts outside the repository. The current
target is described in [the design specification](../DESIGN_SPEC.md) and
[the token system](DESIGN_SYSTEM.md).

## Visual direction

- Independent modern mobile presentation with calm neutral canvas, white inset
  groups, smooth component-specific shapes, crisp type and minimal chrome.
- Primary red `#E00D42` and bundled Plus Jakarta Sans retained. Role-specific
  radii, spacing, feedback and focus behavior follow `tokens.json`.
- Neutral reference language in prose, example UI and artwork. Original research
  URLs remain in the source register; the design is described through its own
  native patterns, not by another product name.
- A distinct layout from the web portal while sharing business rules and brand.
  Portal CSS, desktop navigation and long panels do not dictate phone composition.

## Per-view review

- Purpose, entry/exit, readable title and common action are clear.
- Main actions and current responsibility precede rare record details. Grouped
  rows have labels, consistent destinations and 56-unit starting heights.
- No duplicate page heading, identity dump, technical session prose or pointless
  intermediate view containing only one navigation button.
- Read-only account/placement/vehicle values use named detail pages. Sensitive
  fields appear only for a selected operation; existing guards remain intact.
- Color, control boundaries, component-specific radius and finite depth have a
  purpose. A shadow, tint or blur alone never identifies a control or permission.
- Primary action, navigation, sheet and keyboard reserve their measured space.
  Both hands, safe areas, 200% text, 320-width reflow and explicit Back are covered.
- Maps retain the authorized saved stop, address fallback and attribution.
  Evidence, money, addresses and fields remain on opaque readable surfaces.
- Reduced motion/effects preserves immediate feedback and a legible flat fallback.

## Domain and implementation boundaries

Preserve rider-claimed seller pickup, hub-assigned final-mile delivery, current
eligibility, genuine evidence, buyer-only completion and separate cash facts.
Unavailable resources remain unavailable. Scope and screen counts describe
planning coverage, not completed routes or guaranteed delivery effort.

Record specified, illustrated, implemented and physically verified states
separately. Core colors/shapes now apply to existing screens; future views and optional
candidates remain planned. Styling does not add their data or permission APIs.
Validation includes token consistency/contrast, references, generated documents,
visual artifact inspection and privacy checks. Illustrations use synthetic data.
