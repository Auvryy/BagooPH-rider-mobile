# Pull request draft

Title: Improve rider registration, company requests and daily work

## Description

Current registration and earnings responses could fail in the rider app because
the client omitted required consent fields and rejected the original earnings
ledger. Registration now loads current sex choices and Terms/Privacy versions,
requires explicit consent, and preserves entered details when the service needs
a retry. Cash and Trips show released/pending earnings separately from COD;
Home and Cash explain counted hub receipts and shift blockers.

Riders can use Profile → Assignment to browse companies, submit a request with
explicit work-profile sharing, review exact hub/vehicle/working arrangements,
and accept, decline or withdraw. Stale offers are rechecked before dispatch.
Interrupted commands retain the original UUID and body for recovery. Acceptance
records the assignment and leaves duty off. Company notices open current native
details after access and ownership checks.

Home puts task work first. Selecting a parcel shows its saved stop; the sample
map is optional and labelled. Both renderers support the saved pin without
claiming live tracking or a calculated road route. Hidden or replaced maps
release their old renderer and ignore late callbacks.

## Validation

682 Flutter tests passed with six intentional/configuration-dependent skips;
four map-runtime checks passed. Static analysis was clean, and both configured
Linux and Android debug builds passed. The dedicated company-kernel check also
passed. See the [branch evidence](README.md) for commands and scoped assessment.
The isolated native-Dart/Laravel check uses a frozen committed backend, SQLite
`:memory:` and an explicitly mocked secure-storage adapter. It exercises current
registration/financial reads, interrupted submission, stale-offer rejection,
exact acceptance and one retained consent/placement while duty remains off.

## Remaining acceptance

Physical Android camera/permissions/gesture/restart checks and deployed company
acceptance remain separate. Existing independent parcel, prepaid, cash, message,
notification and handover write gates retain their settings. This branch changes
the rider client and its checks; it does not publish web/backend or buyer-app
changes. No additional routing service, push provider or store release is added.

This description is a local draft. It has not been saved on GitHub.
