# Rider road routing

The November 2 request selects real road lines for assigned Rider stops. It
supersedes the sample-only routing decision for this scope. The map remains
OpenStreetMap-based, with an explicitly started and disclosed route request.

Reviewed Rider main: `efbfed3`. Reviewed Bagoo web location branch: `ce98a8b`,
based on main `c55046c`; its seller and hub stop-pin changes are local source,
not evidence of deployment. Existing Rider task authorization and custody
rules remain authoritative. No location history is stored or sent to Bagoo.

Work proceeds in three parts: verify provider geometry and endpoints; connect
an opt-in configured road provider to the existing navigation controller; and
show its current authorized route in the mobile map. Missing configuration,
coordinates, permissions or valid provider results must not produce a fake
line. Keep request cancellation and task/account lifecycle handling intact.

PC verification uses serial Flutter tests and the bundled map renderer tests.
Actual provider credentials, deployment, Android GPS, permissions, lifecycle and
physical-device map acceptance remain open. The local work tracker was
unavailable; no remote task or timer is claimed.

Route-integrity milestone: 18 focused Geoapify and navigation tests passed on
the PC, including rejection of mismatched endpoints and disconnected sections.
Provider activation and map rendering are still in progress.

See the [task map](../../TASK_TRACKING.md), [backlog](../../SUBTASK_BACKLOG.md)
and [source rules](../../SOURCES.md) for existing dependencies and evidence.
