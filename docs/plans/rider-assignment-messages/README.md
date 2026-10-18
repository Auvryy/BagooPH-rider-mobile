# Rider assignment Messages

Selected October 18, 2026 on `feat/rider-assignment-messages`, from merged Rider
main `8d68566`. This package owns the requested Messages page and its current-stop
entry. It links [M10](../../backlog/M10.md), [HDB-13](../home-dashboard-branch-plan/13-rider-assignment-messages.md)
and the messaging part of [OPS-04](../native-operations/04-messages-notifications.md).
It does not replace the five-batch integration plan.

## Source and dependencies

The website checkout was read without modification at
`a36f468726bcba9e2871056fcb6232f8388770d9`. Reviewed sources: the native operations
contract/OpenAPI, `RiderMessagingController`, `RiderMessagingService`,
`CourierMessagingService`, command retention, connected/boundary tests and the
courier/core-flow rules. The accepted native v1 APIs already exist in source.
The local revision and earlier duty/claim acceptance do not verify Azure chat.

The selected shared session, bounded first-party transport and protected command
storage are implemented. The prior pickup/delivery/Trips branch is merged; its
Azure/physical acceptance remains open. HDB-12's durable notifications inbox is
unimplemented and unselected. This slice does not implement it as an implicit
prerequisite or claim its acceptance: Messages uses its own authorized resources,
and adds no global unread badge or notification acknowledgement.

## Intended behavior

- Load only server-returned phase/assignment/participant threads, with paged
  conversation and message history, returned unread counts and safe avatars.
- Keep a phone list/thread Back path and a wider split view. Preserve keyboard,
  bottom-navigation clearance, ordinary scrolling and 200% text readability.
- Bind drafts to their exact original thread. Revalidate sending after resume,
  assignment or participant changes; never move seller text to a buyer.
- Validate 1–1,000-character plain text. Protect one original send/read UUID intent
  before dispatch, reconcile uncertain results, and retry only the original body.
- Acknowledge only the selected, foreground, rendered incoming message boundary.
  Listing threads, offstage panes and arrivals outside the viewport do not read.
- Reuse the shared foreground refresh/request budget; pause private reads in
  background and clear private state on account/access loss.
- Resolve Message from an owned current stop using returned thread resources
  and fresh task/participant permission; never construct a recipient from a name.

New chat writes have a separate default-false deployment acceptance switch. No
new Geoapify key, websocket, push provider, unrestricted directory, attachment
upload, client-generated notice or backend modification is selected.

## Work and evidence

Estimated client effort: **24 hours**, planned October 18–25 inclusive, excluding
external acceptance waiting. Measured work is recorded separately.

1. Contract models, protected intents and live repository.
2. Paged controller, exact displayed reads, drafts and lifecycle.
3. Responsive list/thread and authorized stop shortcut.
4. Local/native verification, ordinary builds and cumulative API checklist.

See [TESTING.md](TESTING.md) for acceptance and
[../../api/MESSAGES_NEEDS.md](../../api/MESSAGES_NEEDS.md) for API-owner evidence.
Local tests and builds cannot complete authorized Azure/cross-role or physical
Android acceptance. The user controls publication.
