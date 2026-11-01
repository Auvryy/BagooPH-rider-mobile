# Local verification

November 1, 2026. Client scope: delivery completion/earnings guidance, specific
website recovery access and bounded build resources. Mobile source starts at
`4367331`; the backend reference stays read-only at `f001d39`.

## Current local results

| Check | Result |
|---|---|
| `flutter analyze --no-pub` | Passed; no issues. |
| `flutter test --no-pub --concurrency=1 --reporter=json` | 691 passed, six expected skips; runner exit zero. |
| Earnings footer regression | Both available/unavailable cases passed; pending polling timers are cleaned up by the test harness. |
| Configured Linux debug build | Passed, including the PC phone frame. Native compilation uses a single Ninja job during verification. |
| Configured Android debug build | Passed with the limited Gradle configuration; `app-debug.apk` produced. |
| Documentation and Git scope | Relative links, explicit changed-file privacy and whitespace checks pass; the local operating guide stays ignored and untracked. |

The six skips retain opt-in historical rendering/benchmark/configuration work
and the separately invoked company integration case. This delivery did not
rerun that native-to-kernel company suite or certify a new deployed session.

State tests cover committed completed/delivered/unknown outcomes, retained
recovery instructions and changed commercial status invalidating a reviewed
stop. The committed result is described without assuming a later receipt;
historical Delivered results direct the rider to refresh current Trips.

UI tests exercise available/unavailable earnings, trusted fixed recovery URLs,
no account/credential query parameters, a failed website launch, 320px doubled
text and unchanged first-screen Settings controls. Password recovery no longer
passes by opening a placeholder explanation. Existing tests caught Settings
growth; the security link now sits in its compact account group.

Builds and checks are sequential. Android uses a 1 GB Gradle heap, 512 MB maximum
metaspace, one worker, disabled parallel tasks, no persistent build daemon and
in-process Kotlin compilation. The heap limit is not a claim that all build
processes together consume at most 1 GB.

## Assessment and remaining limits

| Client behavior | Before | Verified result |
|---|---|---|
| Delivery/earnings guidance | Unconditional buyer-confirmation and unavailable-earnings copy contradicted recorded results. | Committed completion, cash and earnings are distinct across task/result/history views. |
| Recovery access | Password recovery opened a placeholder; relevant security and recovery destinations were missing. | Fixed first-party password, sessions, cash and custody destinations are reachable, including failed-launch handling. |

These results cover the selected client behavior, not whole-system readiness or
deployed delivery acceptance. Website sign-in/revocation and physical lifecycle
checks remain separate. No endpoint, assignment, cash
record, approval, order status or production setting was changed by this client.

All independent operational write gates are unchanged. The user explicitly
deferred phone testing while another mobile project uses the device. The
[remaining backend needs](BACKEND_NEEDS.md) and [rehearsal](REHEARSAL.md) stay open.
No physical camera/GPS, release signing, closed-app push, live routing, deployed
Wallet proof repair or full cross-role live success is claimed.

## Local handoff

- `9b2d888` — show recorded delivery completion and earnings.
- `aa76171` — open account and cash recovery workflows.
- `ebb6992` — limit Gradle memory and parallel workers.
- Final documentation commit is recorded in the branch's handoff. No commit was
  pushed and the [PR description](PULL_REQUEST.md) is local.

From the rider repository:

```sh
flutter run -d linux --debug --dart-define=DEVICE_PREVIEW=true --dart-define-from-file=.env.rider.json
```
