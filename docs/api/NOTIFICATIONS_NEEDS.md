# Notifications API acceptance checklist

Owning client plan: [Rider Notifications](../plans/rider-notifications/README.md).
This is the selected notice part of [API-H07](HOME_DASHBOARD_NEEDS.md#api-h07).
No new notification endpoint or API key is requested by the current source review.

## Confirmed in backend source

- [x] GET `rider/notifications` returns owned durable rows, exact UUIDs, nullable
  authorized targets, stable page metadata and authoritative `unread_count`.
- [x] POST `rider/notifications/{notice}/read` takes an empty JSON object.
- [x] POST `rider/notifications/read-through` takes exact `displayed_ids`, 1–50
  distinct lowercase UUIDs, with no time cutoff.
- [x] Reads require the notification token ability and retained actor-owned UUID
  commands; `rider/commands/{key}` reconciles original committed read IDs.
- [x] The durable delivery service uses recipient/source uniqueness, after-commit
  delivery and retained retries. The schedule declares minute-based pending
  notification delivery. Source presence does not prove deployed execution.

Reviewed revision and implementation paths are in the owning plan.

## Still needed for Azure acceptance

- [ ] Verify deployed revision, relevant migrations, fresh
  `operations_api_version: 1`, Home notification capability and native
  `rider:operations:notifications` ability.
- [ ] Verify `notifications:deliver-pending` executes on schedule, its retry
  backlog and any relevant account-delivery worker configuration. Provide
  sanitized results only; no host, token or mail credentials in project docs.
- [ ] Designate an approved isolated rider and genuine test event/resources.
  Do not reuse an accepted production claim to create a notification.
- [ ] Compare native pages/counts and one/exact-displayed reads with saved website
  state; later unseen arrivals and foreign IDs must remain untouched.
- [ ] Verify same-key result lookup/replay, uncertain recovery, expired retained
  lookup and quota response with original command rows preserved.
- [ ] Revoke a designated linked task/cash resource and confirm fresh native
  authorization denies it while the saved notification remains readable.
- [ ] Complete actual Android foreground/resume, Back/accessibility and private
  account cleanup separately from desktop and local kernel results.

Keep `NOTIFICATIONS_WRITES_VERIFIED` false until the selected deployed read gate
is accepted. This switch is independent of parcel, Messages and duty/claim writes.
