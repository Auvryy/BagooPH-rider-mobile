# OPS-04 — Assignment-bound messages and notifications

State: **planned, not activated**. Needs shared command/session/access lifecycle,
current assignment resources and deployed durable notification workers/scheduler.
Associations: B10-A–B10-D and B12-A–B12-C; inspect all transitive prerequisites.

## Contract and implementation slices

GET `rider/conversations` and selected `/conversations/{thread}/messages`;
POST that thread's `/messages` and `/read`; GET `rider/notifications`;
POST `/notifications/{notice}/read` and `/notifications/read-through`.

1. Use the returned phase/assignment/participant thread reference and current
   permission. Pickup addresses the seller; final-mile addresses the buyer chosen
   by the server. A stale draft keeps its original recipient and cannot be
   silently moved into another assignment or participant.
2. Send exact normalized text and retain its UUID intent; read only the displayed
   incoming boundary `through_message_id`. Respect active-phase sending, the
   existing identical-text guard and retained command results.
3. Notifications come from durable server events. Mark one owned notice or an
   exact `displayed_ids` list (1–50 distinct lowercase UUIDs). Do not acknowledge
   unseen arrivals through a time cutoff. Reauthorize supported destinations;
   null/unknown/stale targets are readable without invented navigation.
4. Share bounded foreground refresh, pause in background and reconcile read/send
   intents under limits. Keep the existing keyboard/chat lifecycle usable.

Primary ownership: Messages models/repository/controller/pages and a notification
feature module. Shared poll/journal/authorization hooks have one coordinated owner.
No new chat store, websocket or push-provider infrastructure is selected here.

## Finish evidence

- Local tests cover draft ownership, stale/foreign threads, duplicate/uncertain
  sends, exact displayed reads and unknown/late notice targets.
- Real authorized Azure conversations/messages/notices agree with the owning
  website state; removed assignment/participant and foreign read IDs reject.
- Actual Android typing, keyboard, back, foreground/background/resume and private
  cleanup work. Unseen notices/messages are not marked read by a UI tap alone.
- No mock response or client-generated notification clears operational acceptance.
