# Design source register

Reviewed **October 6, 2026**. Neutral reference labels keep external company
names out of design prose, example UI and artwork. Original source URLs remain
unchanged for verification. Guidance was fetched, not inferred from a model's
memory; each use below is a short paraphrase or project adaptation.

Current guidance, historic research and product decisions are different.
The brand palette, page counts, 960-unit split threshold and action geometry
are product proposals. They are not requirements imposed by a platform or
results of a Rider usability experiment.

## R01

[Current mobile layout and safe-area guidance](https://developer.apple.com/design/human-interface-guidelines/layout)  
[Published content data](https://developer.apple.com/tutorials/data/design/human-interface-guidelines/layout.json)

Live guidance retrieved through published content data because the HTML
requires scripts. Used for content importance, readable grouping,
progressive disclosure and device-safe placement. It does not mandate the
Rider palette or exact responsive threshold.

## R02

[Current navigation-material guidance](https://developer.apple.com/design/human-interface-guidelines/materials)  
[Published content data](https://developer.apple.com/tutorials/data/design/human-interface-guidelines/materials.json)

Content retrieved October 6; visible change log includes September 9, 2025.
Used for functional layering, restrained visual material and contrast-aware
fallback. The Rider proposal uses opaque working surfaces; it does not claim
a native material has already been implemented.

## R03

[Adaptive window guidance](https://developer.android.com/develop/adaptive-apps/guides/use-window-size-classes)

Page updated September 22, 2026; fetched October 6. It describes changing
available width/height, reference size classes and adaptation on resize/fold.
The Rider wide split starts at 960 for its own content geometry.

## R04

[Mobile layout and navigation patterns](https://developer.android.com/design/ui/mobile/guides/layout-and-content/layout-and-nav-patterns)

Fetched October 6. Supports familiar primary navigation and changing the
navigation/layout pairing with available space. Four Rider destinations
represent the project's actual areas, not a memory-law maximum.

## R05

[Current accessibility recommendation](https://www.w3.org/TR/WCAG22/)

The published 2.2 recommendation displays December 12, 2024. Used as a
testable accessibility reference. The detailed understanding pages below
are explanatory support; this document does not assert full app conformance.

## R06

[Text contrast guidance](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html)

Fetched October 6. Used for normal-text contrast and solid-color calculation
interpretation. Computed token ratios are a design check, not a rendered
screen or sunlight measurement.

## R07

[Non-text contrast guidance](https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html)

Fetched October 6. Used for meaningful control/state boundaries and the
distinction between structural separators and discoverable controls.

## R08

[Minimum target-size guidance](https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html)

Fetched October 6. The AA criterion has a 24 CSS-pixel minimum with exceptions.
Rider's 48 logical-unit targets are its larger field-use proposal, not a claim
that CSS pixels, native points and physical millimeters are identical.

## R09

[Focus visibility with authored content](https://www.w3.org/WAI/WCAG22/Understanding/focus-not-obscured-minimum.html)

Fetched October 6. Used for keyboard/focus clearance around sticky navigation,
action shelves and overlays.

## R10

[Reflow guidance](https://www.w3.org/WAI/WCAG22/Understanding/reflow.html)

Fetched October 6. Supports readable constrained-width layouts with appropriate
exceptions for spatial content. Important textual addresses and controls still
need an equivalent usable presentation.

## R11

[Accessible authentication guidance](https://www.w3.org/WAI/WCAG22/Understanding/accessible-authentication-minimum.html)

Fetched October 6. Used for password-manager/code-paste support and avoiding
routine cognitive puzzles introduced by the design.

## R12

[Jakob's Law explanation by its author](https://www.nngroup.com/videos/jakobs-law-internet-ux/)

Published August 18, 2017; content fetched October 6, 2026. This is a practitioner
heuristic about familiar interaction patterns, not a measured law establishing
the correct Rider layout.

## R13

[Target acquisition and choice-timing research analysis](https://www.yorku.ca/mack/hci1992.html)

MacKenzie, 1992, author-hosted full article fetched. Used for Fitts' Law,
historical Hick–Hyman context and limitations of comparing devices/tasks.
The original 1952 choice paper and a hosted 1954 movement PDF were also sought;
direct access failed or required library login. We do not claim those full
papers were read. No transfer of published timing coefficients is made to
Rider thumb use.

## R14

[Distinctiveness and memory experiment](https://digitalcommons.usf.edu/psy_facpub/318/)

Fabiani and Donchin, 1995, author-institution record and abstract fetched.
Used to distinguish context-sensitive memory isolation from a universal
claim that a conspicuous colored button improves real task performance.
Full paper access was not required to make that limited observation.

## R15

[One-handed reach study](https://yonsei.elsevierpure.com/en/publications/natural-thumb-zone-on-smartphone-with-one-handed-interaction-effe/)

Kim and Ji, 2019 publication from the 2018 conference; institution abstract
fetched. The studied phones/grips are not the entire current device population.
Used to justify checking hand/device variation and not assuming the lowest
screen edge is comfortable for every user. No published percentages are
adopted as a Rider performance prediction.

## R16

[Working-memory capacity reconsideration](https://pubmed.ncbi.nlm.nih.gov/11515286/?dopt=Abstract)

Cowan, 2001, metadata and abstract fetched. Used to explain contextual memory
limits and why seven or four is not a universal maximum for interface choices
or the number of pages. A memory experiment does not dictate the app's tabs.

## Local authority and design review

The Rider project base reviewed for this task is
`caf58f9b2d7f7aefe02bbdc735cf148c021e52d2`. Its selected features and
operational flow remain authoritative for this frontend plan.

The scoped website review used local revision
`0e4839e773bdcf726933a22efd69c4400018d658`, with another maintainer's roadmap
work in progress. Relevant Rider style, flow, scope, registration/recovery
and courier/eligibility code were inspected. No website files or operational
backend policies were changed by this design task.

This is a source/documentation review. No deployed native API, browser
walkthrough, physical-device test or measured usability improvement is claimed.
Revisit live guidance and the accepted contract when implementation begins.
