# Rider delivery guidance and recovery access

Selected November 1, 2026. Mobile baseline `4367331`; read-only web/backend
reference `f001d396b0e9ea6bfc2fdeb85ee24b66682b997e`.

The current web version-two contract completes a new order from valid delivery
evidence. Historical orders retain their own completion evidence. The native v1
envelope supplies `commercial_status` independently of `operational_stage`; its
API version is not the order's logistics version.

This delivery covers [M01, M07, M11, M14, M15 and M16](../../TASK_TRACKING.md):

- Use the committed commercial status in delivery success and recovered-command
  notices. A completed order is reported as completed; a delivered checkpoint
  alone cannot establish completion, remittance, earnings or payout.
- Preserve the backend's task/recovery instruction, correcting only its known
  obsolete unconditional buyer-confirmation sentence. Ended orders display their
  recorded completion state. Changed commercial status invalidates the stop the
  rider previously reviewed, even if other fields did not change.
- Explain available original-ledger earnings without contradicting the summary
  or interpreting collected COD as income. Notification cash details remain COD
  evidence, without a blanket claim that earnings are unavailable everywhere.
- Make forgotten-password, session-security and restricted custody recovery
  reachable through fixed first-party website destinations. Pending cash offers
  link to the existing cash website for authorized review/cancellation.

The Login and Settings Help recovery links use the dedicated
`/custody-recovery/sign-in` page. The protected `/custody-recovery` page is for
an already authenticated and verified session; sending a restricted rider there
can route them back through ordinary sign-in instead of the narrow recovery
flow. Bagoo verifies the rider's current, owned recovery authorization after
sign-in; opening the link does not clear account restrictions.

These links use the website's own session. No app token, account identifier,
password or private record is appended to the URL. The website rechecks its own
permission. Opening it does not perform an operation inside the native app.

## Verification and scope

Local verification and final commit evidence are recorded in
[VERIFICATION.md](VERIFICATION.md). The [rehearsal checklist](REHEARSAL.md) keeps
remaining operational checks explicit. The user selected PC verification now
and deferred phone testing; no phone session is used by this delivery.
The [private-data lifecycle audit](PRIVATE_DATA_LIFECYCLE.md) records current
source behavior and the still-open owner policy decisions for pending commands,
message drafts and parcel photo recovery.

Existing independent parcel, prepaid, cash, message, notification and handover
write gates are unchanged. Live-account signup/login is not replaced by fixtures.
The Wallet recipient/proof repair and version-two handover regression are now
implemented on Bagoo branch `fix/rider-wallet-trip-evidence`; the focused backend
suite and Rider native prepaid consumer check passed locally. The source branch
is not merged or confirmed deployed. Azure acceptance and hardware checks remain
separate; see the [backend follow-up](BACKEND_NEEDS.md).

Builds now use a 1 GB Gradle heap, one Gradle worker, no parallel Gradle tasks
and no persistent project build daemon. Kotlin compilation stays in that process.
These settings bound the Java heap, not the total memory of every compiler.
Linux verification uses one Ninja job and all checks/builds run sequentially.

No package identity, signing key, dispatch policy, GPS/routing service, additional
endpoint or external provider is introduced. The current street map remains a
saved-stop map with an optional labelled illustration.

Run from the rider repository:

```sh
flutter run -d linux --debug --dart-define=DEVICE_PREVIEW=true --dart-define-from-file=.env.rider.json
```
