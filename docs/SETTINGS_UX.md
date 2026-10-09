# Profile and Settings mobile layout

Implemented October 9, 2026. This presentation update follows the existing
courier profile and email flows, with backend source reviewed at `8fb5193`.
The web owner is developing APIs separately; no backend file or contract is
changed by this UI work. Ordinary application runs still select Azure.

## Information hierarchy

Profile starts with a compact account card and a Settings row. Account details,
assignment and vehicle/credential records each have a named detail page. Long
read-only records no longer push Settings beneath the first phone viewport.
Unknown managed details remain unknown; identifiers and human names retain their
server values. Only known status labels get readable spacing/capitalization.

Settings uses Account and Support groups with 56-unit rows, labelled icons,
disclosure chevrons and a separate sign-out row. Contact, email management and
password changes are directly reachable; the single-action security page and
duplicate Profile-toolbar actions are removed. Both system Back and the visible
back control follow the same parent hierarchy.

Contact puts the editable number and Save action first. Read-only name/email and
saved-number repetition is removed. Reviewed identity guidance appears on demand
under “Need to correct your name?” and retains its specific website workflow.
Password goes directly to the required fields; forgotten-password recovery
remains a specific supported action.

Email and recovery first shows saved addresses and Add email. Current-password,
new-address and code inputs appear only in the corresponding add/manage screen.
An original preferred sign-in address has no unnecessary password field or Remove
control. Other permitted address actions still recheck the controller snapshot,
require current password and preserve removal confirmation. Codes/cooldowns,
recipient binding, capability gates and secret cleanup remain intact.

Help uses named expandable topics. About keeps version/build and licences in a
short list. Technical session explanations and repeated brand paragraphs are
removed from the everyday Settings path.

## Design rationale

- **Progressive disclosure:** keep common choices visible and reveal detailed
  records or operation-specific fields on request. This follows
  [NN/G's progressive-disclosure guidance](https://www.nngroup.com/articles/progressive-disclosure/).
- **Grouping and recognition:** related options share an inset group; text labels
  and chevrons show their purpose and destination. The pattern is inspired by
  [native list-and-table guidance](https://developer.apple.com/design/human-interface-guidelines/lists-and-tables).
- **Touch and text:** entire rows are interactive, with at least 48-unit targets.
  Compact spacing does not reduce text to fit. Large text may scroll vertically;
  fields, long values and keyboard paths must remain accessible.
- **Consistency:** preserve Bagoo red, use system sans-serif type and continuous corners. Detail
  pages share navigation and row structure. The follow-up shared-theme update
  applies neutral canvas, 20-unit groups and 12-unit controls to existing screens.
  The supplied brand artwork retains its contour.

## Verification scope

Layout checks measure all main Profile/Settings controls within the initial
390 × 844 phone viewport at normal text, along with minimum target heights.
They verify detail-page value preservation, system Back, collapsed Help/identity
information, separate email actions and original-email protections. Small-width,
200% text and keyboard checks allow vertical scrolling and reject overflow.

Rendered review images under ignored `build/settings-ui` use synthetic test data.
They verify visual composition, not live API mutations or physical Android input.
The standard app contains no sample-page route or automatic test-account login.

Final verification: analysis clean; all 85 local Flutter tests passed, including
five new hierarchy/layout scenarios. Ordinary Linux and Android debug builds
passed. The APK retains Azure and excludes retired sample routes. Review images
were inspected with the actual bundled text/icon fonts loaded. No Android phone
was connected, so physical typing/touch behavior remains a device check. No live
password/email/contact mutation or backend edit was performed for this redesign.
