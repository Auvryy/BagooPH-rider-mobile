# Rider interface redesign

Status: in progress on `feat/rider-ui-redesign`.

## Scope and authority

Redesign every implemented page and its loading, empty, denied and error states,
using the three user-selected delivery/ride images as composition references.
Keep Bagoo's logo and `#E00D42`, all functions and server permissions. Update the
canonical design docs so later work follows this direction. The proposal catalogue
of 48 views remains separate from the implemented-screen coverage below.

Reviewed mobile baseline `3b4c188` and backend main `a978e82`. Backend roadmap,
existing account/operations/Settings/handover contracts and client repositories
remain authoritative for behavior. This presentation work changes no backend
files, deployment, API gates, real records or physical-custody rules.

Cross-cutting owner: [M02](../../TASK_TRACKING.md#m02--flutter-foundation-and-design-system) and the existing
M03/M04/M09/M10/M11/M13/M14 presentation surfaces. Follow the
[backlog](../../SUBTASK_BACKLOG.md), [source authority](../../SOURCES.md) and
[design specification](../../DESIGN_SPEC.md); this does not activate future APIs.

## Focused commit sequence

1. Canonical visual direction, tokens and shared surfaces/type.
2. Account entry, three registration steps, verification/holding and navigation.
3. Home overview, task cards/details, maps, navigation and Stop Mode.
4. Trips, Messages, Profile/Settings and Handover pages/forms/viewers.
5. Render review, accessibility/functional regression checks and final evidence.

## Implemented-screen coverage

- [ ] Login, registration stages, documents, verification dialog and holding.
- [ ] Persistent bottom bar, wide rail, keyboard/Back behavior and sign-out.
- [ ] Live Home summary, queues, selected task, available claim and address fallback.
- [ ] Map controls/attribution, route states, manual origin/profile and Stop Mode.
- [ ] Trips list, filters, summaries and trip details.
- [ ] Messages list, thread, compose, errors and restricted states.
- [ ] Profile, Settings, managed records, help and contact/password/email forms.
- [ ] Handover list, detail, report, acknowledgement and private evidence viewer.
- [ ] Shared empty/loading/error/unavailable states, dialogs and sheets.

## Behavior invariants

Keep live Azure login in ordinary builds; synthetic data belongs only in tests.
Home remains ordinary scrolling. Reserved navigation cannot cover content.
Preserve task identity, refreshed ownership, command reconciliation and version
gates. Navigation starts/stops explicitly; GPS does not change custody. Map
attribution, null-coordinate address fallback and external directions remain.
Preserve private evidence access, exact amounts, field validation, session cleanup,
keyboard focus, labelled controls, 48-unit targets and reduced motion.

## Finish evidence

Pending: rendered real-font reviews of every screen family at phone dimensions;
compact/200% text and wide layout checks; targeted/full Flutter tests; analysis;
ordinary Linux and Android builds; privacy/diff review and focused local commits.
Render fixtures do not establish new live operational or physical-device acceptance.
No changes to API or device gates are claimed by this work.

## Verification log

- Shared visual foundation: 14 theme/surface tests passed; design catalogue
  generator validated unchanged counts and stable IDs.
- Account/navigation slice: 36 account, lifecycle, workspace and render checks
  passed. After refining login spacing and loading actual icon fonts, the
  22 account/render checks passed again. Synthetic captures include login, all
  three registration stages, holding and the four workspace roots. Compact
  320–430, 200% text, wide layouts and message keyboard behavior are covered.
- Home/Stop Mode slice: 38 Home/overview checks passed after adapting lazy-scroll
  assertions to the map-first order. Stop Mode and navigation checks passed in
  the preceding targeted run. Reviewed phone overview and address-only directions
  captures; map test tiles are synthetic and do not establish live routing.
- Trips/Messages/Profile/Settings/Handover slice: 51 targeted functional, layout
  and opt-in render checks passed, including all Settings flows, handover report
  and acknowledgement, private-evidence denial, large text and keyboard clearance.
  Registration step numbers no longer imply validation when a later step is opened.
  Solid white app bars finish the shared navigation treatment.
- Full-suite regression, final analysis and native builds remain pending.
