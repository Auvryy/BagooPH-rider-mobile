# Session Parcel Finder

Selected October 19, 2026 on `feat/rider-parcel-finder`, from merged Rider
`main` `34ac321` (Messages PR 27). This package implements the selected
[HDB-16 brief](../home-dashboard-branch-plan/16-rider-parcel-finder.md) and
[Parcel Finder direction](../../FEATURE_DIRECTION.md#2-parcel-finder).

## Selected scope

The first scope is explicitly **session-only personal labels**. An owned pickup
or supported final-mile task can have one location: Top box left, Top box right,
Bag 1 or Bag 2. Several parcels may share a location. Stop Mode shows the full
tracking identifier, a large distinguishing suffix and an unset state.

Labels live only in the account/API workspace's memory, keyed by task and current
assignment. Ordinary successful refreshes preserve them. Confirmed reassignment,
loss of access, terminal responsibility, logout, API/account changes and disposal
clear the relevant labels. Missing rows from a partial page do not prove removal.
Nothing is persisted, synchronized or uploaded. Restarting the app clears labels.

Every edit revalidates the selected owned task. An available pickup preview,
missing assignment, stale/denied selection or background/covered page cannot
save a label. Labels describe personal organization; the server's separate
custody state remains authoritative. Selecting a location never claims, scans,
collects, departs, delivers or records a handover.

## Sources and prerequisite boundaries

Reviewed backend `7c1bb59e457eb75d8374a5efd5ef6c91d1bb0d5f` without modification:
the core roadmap, courier queue/task services, native task contract and relevant
ownership tests. Owned queues positively scope the current rider and active
phase; task detail resolves through those queues. Assignment references identify
the current source checkpoint. This feature adds no endpoint, dependency, key,
permission or backend mutation.

HDB-04 Stop Mode and the HDB-07 pickup foundation are merged. Their local
verification is recorded in [Stop Mode](../home-dashboard-branch-plan/HDB-04-EVIDENCE.md)
and [parcel/Trips verification](../rider-orders-delivery-trips/VERIFICATION.md).
Their Azure/physical acceptance remains separate. This bounded presentation
does not certify the canonical backlog's transitive operational gates, activate
deferred parcel/message writes or implement other HDB branches.

Estimated client effort: **five hours**, October 19–25 inclusive, ending before
the November 20 development deadline. Measured work is recorded separately.

## Implementation and verification

1. Session-scoped labels and authoritative observation/cleanup.
2. Accessible inline compartment selection, tracking identity and Stop Mode entry.
3. Controller/widget regressions, rendered review, analysis and native builds.
4. Verification record and cumulative external handoff.

See [TESTING.md](TESTING.md). Local feature acceptance is distinct from the
already-pending deployed parcel/Messages and physical Android acceptance.
No new backend work is requested by this feature. The user handles publication.
