# Messages API needs checklist

Owner: [selected Messages slice](../plans/rider-assignment-messages/README.md).
This is a consumer checklist, not a second wire specification. The website owns
the executable native operations v1 contract.

## Source exists

- [x] Paged `GET rider/conversations` and selected thread `/messages`.
- [x] Exact thread includes phase, delivery, original current assignment and
  participant identity. Seller pickup and buyer final-mile stay separate.
- [x] Thread `can_send`/denial, returned unread count and nullable safe avatar.
- [x] `POST /messages` accepts only validated text and an idempotency UUID.
- [x] `POST /read` accepts an exact selected `through_message_id`.
- [x] Retained command lookup, identical-key replay, stale/foreign/expired
  rejection and the existing two-second identical-text guard.

Read at backend `a36f468726bcba9e2871056fcb6232f8388770d9`; source availability
does not prove deployment or actual owning-role parity.

## API-owner live confirmation still needed

- [ ] Confirm Azure's actual deployed commit, native command migrations and
  private/no-store JSON responses. Report sanitized evidence only.
- [ ] Designate an isolated approved rider and fresh native sign-in advertising
  operations v1; verify Home's messaging capability and message token ability.
- [ ] Prepare one eligible pickup/seller thread and, sequentially through owning
  domain workflows, one assigned final-mile/buyer thread. Supply sanitized
  references without credentials, contact details or production message text.
- [ ] Authorize clearly labelled software-test text and a seller/buyer reply.
  Verify one persisted send per original UUID through the actual owning web view.
- [ ] Introduce an unread arrival after a displayed boundary. Verify it remains
  unread, and another rider/phase/assignment cannot read or send through that ID.
- [ ] If controlled reassignment is available, verify old draft/send denial and
  fresh participant identity. Do not fabricate custody/source state for testing.
- [ ] Confirm failures/429 and seven-day retry behavior without deleting retained
  command results or altering the accepted duty/claim fixtures.

The user will forward the cumulative handoff later. No new API is requested
unless implementation/verification identifies a concrete gap. No additional map
key is needed. Phone-only acceptance remains separate from these API checks.
