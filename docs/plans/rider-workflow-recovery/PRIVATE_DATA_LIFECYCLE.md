# Rider private-data lifecycle audit

Source audit: November 2, 2026. This records current implementation behavior
and remaining policy decisions. It does not constitute owner acceptance.
The related [command replay decision](../../backlog/M01.md#m01-06) and
[private draft/interruption decision](../../backlog/M16.md#m16-02) remain
planned.

## Current implementation

| Data | Storage and scope | Interruption and cleanup behavior |
|---|---|---|
| Bearer token | `SecureTokenStore` uses Flutter Secure Storage with a key derived from the API origin. The token is not a field in `CommandIntent`. | `clear()` deletes the origin-specific and legacy token keys. This audit does not certify OS-level storage behavior on a physical device. |
| Pending commands | `SecureCommandJournal` persists the complete JSON `CommandIntent` through Flutter Secure Storage. Its key is scoped by API origin, account and one of `work`, `messages`, `notifications` or `company`. | The body is persisted for exact replay. Depending on action it can contain recipient name/relationship, notes or location, cash terms, message text, notification IDs, or company request details. The journal also includes account, command key/action/resource/time and, for parcel proof, a small key/hash/extension reference. It contains no proof image bytes or bearer token. |
| Unknown command result | One unresolved intent blocks a new command in that scope. Successful reconciliation and selected definitive rejections clear it. Logout/account change does not delete the unresolved journal. | The command adapters permit an unchanged retry for up to seven days. After that, an unknown result is not automatically deleted: retry is refused, but the intent remains available for status checking and continues to block a replacement command. The cutoff is a retry limit, not a retention or purge policy. |
| Parcel proof for a command | Original image bytes are stored separately in application-support files, encrypted with AES-GCM. The key is in Flutter Secure Storage; the file and key/reference are scoped to API origin and account. | Before dispatch, the work repository copies the selected image under the command's own key. That proof remains available for same-account reconciliation after logout and after the temporary photo draft expires. It is removed when the command is resolved and cleaned up. Physical-device storage behavior remains unverified. |
| Unsubmitted parcel photo draft | Secure Storage holds a context and proof reference bound to API, account, task, version, action and a random key. The encrypted original is separate. Android lost-picker recovery uses a context marker. | The image is offered only for the matching context and for less than 24 hours. Backgrounding clears the in-memory image and form selection and cancels its expiry callback; resume reloads only the same account/API-scoped encrypted copy if it is still fresh. A draft that expires in the background is deleted during resume restore. A stale in-flight restore cannot repopulate memory after a background/resume transition. Explicit sign-out and invalid-session cleanup remove the owned picker marker and unsubmitted proof; a separately retained command proof is preserved. Sign-out prevents a picker or proof save already in flight from recreating the draft. Manual sign-out is canceled with a retry message if cleanup fails. An approval/restriction transition outside those paths is not yet wired. If the app is stopped without sign-out, expiry cleanup can wait until the next same-account restore. Physical-device behavior remains unverified. |
| Messages | Conversation list, selected thread/history and pending UI intent are held in controller memory. Draft text is an in-memory map keyed by thread. | Backgrounding clears the cached inbox/history and pending UI intent, but leaves message draft text in memory. Losing authorization, stale-thread denial, capability removal or controller disposal clears drafts. Deactivating a surface cancels reads but retains cached state while the controller remains alive. |
| Notifications | Inbox, selected item, pending UI intent and displayed-read tracking are held in controller memory. | Backgrounding clears private inbox/detail/pending state. Access loss, capability removal and disposal clear it too. |
| Retained Trip proof view | Authorized proof bytes are held by the Trip detail controller in memory after an authenticated read. | Backgrounding clears the selected proof and its path; reopening requires a fresh read. Controller disposal also clears the view. |

These are source-level observations, not physical Android acceptance. The
connected phone remains reserved for Buyer Mobile; no phone was accessed for
this audit.

## Decisions still needed

1. Accept or change exact-body persistence for pending commands. Reference-only
   storage cannot replay the unchanged request body; current secure storage can
   therefore hold recipient/contact text and other action details across logout.
2. Define cleanup and recovery for an unresolved command past its retry window.
   Deleting it automatically could hide a command that already succeeded on the
   server. Keeping it indefinitely blocks new writes in that scope.
3. Decide whether message draft text may remain in memory across backgrounding
   and whether inactive message surfaces should retain their cached private data.
4. Confirm the bounded encrypted photo-draft recovery tradeoff: plaintext is
   cleared on background and reloaded only on same-account resume before the
   24-hour cutoff. Explicit sign-out and invalid-session cleanup are wired;
   cleanup on approval/restriction transitions and physical Android lifecycle
   acceptance remain open.
5. Confirm acceptable token, journal and proof protection on supported Android
   versions, including real process death and lost-picker behavior.

Until these choices are accepted, describe the implementation as scoped and
recovery-oriented, with the retention questions open. Do not describe pending
commands as reference-only, do not equate the seven-day retry cutoff with
deletion, and do not claim that every private draft clears on background.

## Source references

- [Token store](../../../lib/core/security/token_store.dart)
- [Command intent](../../../lib/core/commands/command_intent.dart) and
  [secure command journal](../../../lib/features/home/data/command_journal.dart)
- [Parcel proof store](../../../lib/core/commands/protected_proof_store.dart)
  and [photo recovery service](../../../lib/features/parcels/data/parcel_photo_service.dart)
  plus the [photo outcome form](../../../lib/features/parcels/presentation/parcel_outcome_fields.dart)
- [Work command reconciliation](../../../lib/features/home/data/operations_repository.dart)
- [Message lifecycle](../../../lib/features/messages/presentation/messages_controller.dart)
  and [message replay](../../../lib/features/messages/data/messages_repository.dart)
- [Notification lifecycle](../../../lib/features/notifications/presentation/notifications_controller.dart)
  and [notification replay](../../../lib/features/notifications/data/notifications_repository.dart)
- [Workspace lifecycle](../../../lib/features/workspace/presentation/workspace_controller.dart)
  and [Trip proof lifecycle](../../../lib/features/trips/presentation/trip_detail_controller.dart)
