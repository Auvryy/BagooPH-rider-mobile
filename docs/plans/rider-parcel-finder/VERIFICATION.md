# Parcel Finder verification

October 19, 2026 · `feat/rider-parcel-finder` · base `34ac321` (Messages PR 27).

## Resulting behavior

Owned Stop Mode includes an inline Parcel Finder card. It shows a large tracking
suffix, extends collisions among distinct loaded identifiers, and keeps the
full tracking number in parcel details. A rider chooses Top box left/right or
Bag 1/2, changes it or clears it. Locations can be shared by several parcels.
Before recorded possession, a selected location is labelled **Planned**.

Each edit revalidates current owned detail through the existing GET. Missing
assignment, preview, denied access, changed identity, background/covered pages
and superseded selections cannot apply an obsolete edit. No command journal or
parcel write is used, including when operational write gates are disabled.

The in-memory map belongs to one API/account workspace and includes task,
assignment and tracking identity. Fresh matching reads preserve a label.
Confirmed 404, reassignment, tracking correction, ended responsibility and
complete owned queues remove relevant labels. Partial pages and other queues
do not establish removal. API/account/approval changes dispose or disable the
old workspace; logout, session denial and disposal clear private labels.
Failed final-mile work retains its personal label while return responsibility
continues. The server's custody and mandatory hub workflows stay separate.

## Source review

Read-only website review at `7c1bb59e457eb75d8374a5efd5ef6c91d1bb0d5f`:
core roadmap, native task documentation, courier queue/task services and native
ownership/parcel test sources. Pickup queues cover assigned/assigned-pickup/
picked-up work; final-mile queues cover assigned, departed and outstanding
failed-return responsibility. Owned detail resolves through the same scope.
The original assignment checkpoint supplies `assignment_reference`.

No backend file, branch, migration, production record or endpoint changed.
This is a local-only extension over the accepted task reader, with no new
package, platform permission, key, location service, persistence or API contract.
HDB-04 and parcel/Trips local foundation evidence is linked from [README.md](README.md).
Their separate deployment/device acceptance is not completed by label tests.

## Local evidence

| Check | Evidence |
|---|---|
| State/controller/provider checks | 13 passed: exact scopes, shared slots, refresh/reassignment/terminal cleanup, partial queues, one GET, late edits, 403/404/503 and actual provider replacement |
| Picker/Stop Mode widgets | Seven passed with actual bundled fonts/icons, selected/name/focus semantics, Enter-key selection, reachable 48dp controls, ordinary scrolling, duplicate-tap feedback, failure retention and denied private-state cleanup |
| Actual rendered review | 320px at 200% text, 375px phone, 844px landscape, 900px landscape at 200%, 1200px desktop; existing light theme and reduced motion |
| Analysis | No issues, 9.2 seconds |
| Full Flutter regressions | 494 passed, four expected skips; verified exit code 0 |
| Ordinary Linux/Android debug builds | Both passed with exit 0, the normal Azure account entrypoint and the existing ignored configuration |

The initial UI checks exposed unnamed button nodes; the name/selection properties
now merge into each native button. Test-only fake-clock setup and semantics-handle
cleanup were corrected before the passing selected run. No production sample
route or fabricated held parcel was added. No visible Flutter window was opened.

The four full-suite skips are three opt-in historical redesign renders and the
alternate-API configuration case. The existing stale-assignment/wrong-waybill
regression passed: a personal label cannot substitute its suffix for a matching
full waybill or create a custody command. A first full run reached all assertions
but reported an interrupted process exit; the recorded final rerun completed
with exit 0. The final run includes the Enter-key selection check.

Final commands:

```sh
flutter analyze --no-pub
flutter test --no-pub --reporter expanded
flutter build linux --debug --no-pub --dart-define-from-file=.env.geoapify.json
flutter build apk --debug --no-pub --dart-define-from-file=.env.geoapify.json
```

The Android build retained the existing SDK XML-version warning and completed
successfully. No dependency or Android permission changed. Public documentation
links, scoped Git whitespace/privacy checks and private handoff retention passed.

## Scope limits and handoff

Labels intentionally clear on app restart. Persistence, cross-device labels,
custom slots and dispatch batching are separate, unselected work. Physical
Android touch/Back and real Azure task observations remain broader app acceptance;
the user has deferred those checks. This feature needs no web AI implementation.

The cumulative external handoff retains the earlier parcel/Trips and Messages
requests and appends the selected label scope. Existing parcel/message write
gates remain disabled; accepted duty/claim configuration is unchanged.
Follow [TESTING.md](TESTING.md) for PC phone-frame review. The user handles push.
