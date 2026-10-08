# Native workspace API handoff

Reviewed web main: `fe86abf`. The implemented native contract currently covers
account access/registration under `/api/v1`; issued tokens have account/logout
abilities. Courier work, history, messaging and profile changes still use
website sessions and their existing server policies. Flutter cannot substitute
a native bearer for a browser cookie or scrape Inertia pages as an API.

The new mobile pages provide the view/controller structure and explicit
unavailable states. Their presentation models are **not an accepted wire
contract**. The paths below are proposals for the backend maintainer to review;
no mobile request is sent to them. Keep backend implementation in its owning
repository and agree the actual resources/tests before wiring a mobile adapter.

| Proposed capability | Required server evidence |
|---|---|
| Scoped Home queues | Available seller pickups, the rider's active pickups and hub-assigned final-mile work; authoritative counts, company/hub/assignment scope, duty/capacity and allowed actions. Preserve supplied order and distinguish empty from denied/failed reads. |
| Scoped trip list/detail | Explicit final-mile/current-assignment/history attribution, allowed search/payment/Manila-date filters, real pagination and recorded checkpoints. Missing payment/time/cash/proof fields stay unknown; delivery is not buyer completion, remittance or earnings. |
| Conversations/thread | Delivery identity plus `pickup` or `final_mile`, server-derived participant, current sending/read permission, bounded message history and actual unread count. No arbitrary contact directory or client-selected recipient. |
| Send message | Current actor/assignment/phase revalidation, maximum 1,000 characters, a stale-recipient/phase condition and a confirmed server message. Do not redirect a stale draft to a different person or automatically retry an unconfirmed send. |
| Acknowledge visible messages | Phase and exact displayed message boundary, idempotent acknowledgement and confirmed unread/read result. Reading one thread cannot mark another phase/thread read. |
| Own profile/managed information | Allowlisted contact and current placement/vehicle fields with explicit missing-value meanings. General profile JSON must not expose private document paths. Existing managed/reviewed data stays server-owned. |

Possible routes, pending the owner's contract decision:

```text
GET  /api/v1/rider/tasks
GET  /api/v1/rider/tasks/{id}
GET  /api/v1/rider/trips
GET  /api/v1/rider/trips/{id}
GET  /api/v1/rider/conversations
GET  /api/v1/rider/conversations/{delivery_id}
POST /api/v1/rider/conversations/{delivery_id}/messages
POST /api/v1/rider/conversations/{delivery_id}/read
GET  /api/v1/rider/profile
```

Reuse current courier operations, messaging, eligibility and validation services.
Confirm narrow native token abilities and existing-token migration/re-login,
expiry/password/restriction invalidation, positive role/ownership/phase checks,
private no-store responses, rate limits, HTTPS and same-origin pagination links.
Off duty retains authorized existing responsibilities; approval alone does not
grant placement or parcel authority. Keep pickup claims separate from hub-owned
final-mile assignment and preserve the mandatory hub routing chain.

Before integration, supply sanitized success/empty/denied/stale/error examples,
the accepted source/deployment revision and isolated contract tests. Flutter then
adds a real shared-transport adapter and verifies cross-role outcomes. Current
preview behavior cannot clear these operational acceptance gates.
