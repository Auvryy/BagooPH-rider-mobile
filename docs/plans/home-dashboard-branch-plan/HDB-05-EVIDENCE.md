# HDB-05 preparation and remaining acceptance

October 16, 2026. Branch `feat/home-duty-claim-acceptance` starts from merged
mobile `main` `179a1ce`. This activates only
[HDB-05](05-home-duty-claim-acceptance.md), the existing duty/claim verification
slice. Scanning, delivery, Trips, Messages and cash remain later deliveries.

## Current result

The existing native Linux read check completed before the user requested that
testing stop. It established a fresh approved session, operations version 1,
handover version 1, decoded Home and an empty involved-handover list. Its one
test passed. It used the existing test rider and an isolated memory-token session;
it performed no duty, pickup claim, report or custody action.

This is evidence that authenticated native Azure reads work. It does **not**
identify the deployed commit, confirm migrations, verify all three operations
queues through their consumer or establish an owned-task/claim success.

An earlier unauthenticated Home probe with a native-style user agent returned
401 JSON, and registration options returned 200 JSON. A generic probe received
403 instead; generic probes are not treated as native acceptance evidence.

The user deferred deployment/test-parcel confirmation, then requested no testing
or Flutter windows during class. The native test process exited. After the goal
was resumed, selected static analysis and headless local checks were completed;
no native app window was opened. Native live execution and domain writes remain
pending. Local checks do not clear deployment or test-resource gates.

## Source and scope review

- Reviewed mobile transport, approved-account/version discovery, account-scoped
  protected command journal, operations repository, workspace write guards and
  HDB-01 recovery evidence. The existing code already sends explicit duty values,
  persists UUID intents before dispatch and refreshes owned detail after claim.
- Reviewed backend `beda044`, native routes, operations controller, task/command
  services, operations contract and duty/claim test source. Its checkout is on
  `fix/portal-notifications` with unrelated notification edits; those files,
  branch and data were preserved. No backend tests or writes were performed here.
- Rechecked the selected backlog associations and canonical prerequisite audit.
  Existing implementations are reused; the broad backlog cards and later
  physical/cross-feature acceptance are not declared complete.
- Actual deployed revision and target-relative migrations remain unconfirmed.
  The user's confidence that Azure is updated is recorded as context, not
  substituted for operator evidence.
- At resumption, backend main was clean at `4b9f610`, after the notification work
  merged. Relevant operations sources remain the reference for this slice;
  that merge does not identify the Azure revision.

## Prepared native operations read check

[The opt-in adapter](../../../integration_test/operations_live_read_test.dart)
uses the ordinary Flutter authentication and operations repository against Azure.
It logs in with a designated existing rider, reads Home and all three first
pages, and refreshes one owned detail per nonempty owned queue. It audits native
JSON/private/no-store/no-cache/nosniff response headers. Empty owned queues remain
empty; they do not count as positive owned-detail acceptance.

The adapter uses an isolated memory token, a journal that refuses writes and
disabled domain-write flags. Only its own authentication session is created and
revoked. It saves aggregate counts/capabilities and verification facts in a
mode-600 receipt beside its private input. It does not save tokens, credentials,
addresses, contacts, parcel identities or proof in that receipt.

This new adapter passes selected static analysis but **has not been executed**.
Map configuration and default duty/claim activation remain unchanged. The client
response validation correction below is verified locally.

## Local duty-result validation

Review found that a committed duty result was accepted whenever `on_duty` was a
Boolean, even when it disagreed with the original requested value. The repository
now requires agreement before clearing the protected intent or reporting success.
A malformed/mismatched response retains the original key and desired state for
reconciliation. It cannot cause another toggle to be sent automatically.

Two regressions, for desired true and false, failed against the previous code:
each wrong-state reply was returned as success. After the fix, both retain their
intent through a mismatched command read, then clear it after a matching result.
Each test verifies one PATCH and reconciliation using the original UUID.

- Selected operations contract, transport and Home read-recovery suites:
  **26 tests passed**, using the headless test engine with isolated responses.
- `dart analyze` on the repository, contract tests and prepared live-read adapter:
  **no issues found**.
- No actual duty/claim request, native-window launch, build or physical Android
  check was performed during this resumed slice. These checks do not replace
  the live acceptance rows below.

When testing is resumed, supply a mode-600 JSON file inside a mode-700 private
directory, outside Git. Its fields are:

| Field | Required value |
|---|---|
| `account_id` | Exact designated rider ID as a decimal string. |
| `email`, `password` | Authorized rider sign-in, supplied privately at runtime. |

Set `BAGOO_LIVE_OPERATIONS_CASE` to the input path; never put credentials in
source or build definitions. The following is a deferred command, not an
instruction to open Flutter during class:

```sh
flutter test --no-pub integration_test/operations_live_read_test.dart -d linux --dart-define=LIVE_OPERATIONS_READ_CHECK=true --reporter expanded
```

Both operational and handover write flags must be false. The adapter is skipped
without the explicit opt-in. It needs no Geoapify key and adds no ordinary app route.

## Resume in this order

1. Obtain operator confirmation of the running revision and required migrations,
   plus a designated isolated ready-for-pickup parcel and eligible rider. The
   web owner prepares resources through normal owning workflows; no production
   reseed, forced custody or blanket API implementation is requested.
2. Analyze and exercise the new read adapter and relevant existing local suites.
   Check the designated resource and fresh Home eligibility before any write.
3. Under the accepted controlled build, verify explicit duty, one claim, same-key
   replay, uncertain-response reconciliation, off-duty retained work and the
   owning website's assignment. Claim is separate from collection or hub intake.
4. Record selected local/native/cross-role evidence, then decide operational-write
   activation. Build and physical Android acceptance remain distinct.

See [the API checklist](../../api/HOME_DASHBOARD_NEEDS.md#api-h02),
[deployment gate](../native-operations/DEPLOYMENT_GATE.md),
[setup](../home-dashboard-navigation/SETUP_AND_ACCEPTANCE.md) and
[acceptance matrix](ACCEPTANCE.md). HDB-05 is not complete; no live write or device
row has been checked by this preparation.
