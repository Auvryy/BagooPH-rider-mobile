# Controlled Linux software-test report

The opt-in [native acceptance test](../../../integration_test/handover_live_report_test.dart)
uses the ordinary authenticated Flutter transport, report form, controller,
repository and protected journal against Azure. It submits one `missed_scan`
report for an expressly designated test parcel. It performs no pickup scan,
duty change, claim, review, possession acknowledgement or receiving action.

The generated PDF records fresh account/Home/owned-task software checks. Its
heading and submitted observations explicitly label it as software-test evidence;
physical possession, location and receipt remain unverified. Use this check only
when the operator has selected that evidence type for a prepared test case.
It cannot certify an actual physical missed scan.

## Private input

Supply a mode-600 JSON file at runtime through `BAGOO_LIVE_HANDOVER_CASE`.
Keep it and all output outside Git, preferably in an ignored directory under
`build/`, with directory mode 700. Do not put credentials or case identifiers in
source, build definitions, terminal arguments, screenshots or committed logs.

The file contains these fields; enter their values privately:

| Field | Purpose |
|---|---|
| `email`, `password` | Authorized existing test-rider sign-in. |
| `account_id`, `parcel_id` | Expected positive decimal string identifiers. |
| `task_id`, `tracking`, `order` | Exact designated owned pickup and waybill/order. |
| `expected_stage`, `expected_status`, `expected_custody` | Required unchanged server preflight state. |
| `deployed_revision` | Operator-verified running revision, not a local Git claim. |
| `output_directory` | Absolute directory containing this private JSON file. |

The test checks the approved account, both API versions, current Home read/write
permissions and exact owned task before dispatching. It
refuses mismatched state, a retained foreign intent or an existing involved report.
If pagination prevents establishing absence, inspect the queue separately first.
The temporary memory-token session does not replace the app's stored login.

From the Rider repository root, with the runtime variable set to that private
file, run:

```sh
flutter test --no-pub integration_test/handover_live_report_test.dart -d linux --dart-define=LIVE_HANDOVER_REPORT_CHECK=true --dart-define=HANDOVER_WRITES_VERIFIED=true --reporter expanded
```

Keep `OPERATIONS_WRITES_VERIFIED` false. No Geoapify key is needed by this test.
Without the explicit live-report definition, the test is skipped.

## Result and restart handling

The test creates private `software-test-evidence.pdf` and `receipt.json` beside
the input. The PDF is opened and rendered by the actual native PDF engine before
upload. The existing encrypted journal retains the original body, UUID and bytes
before dispatch; the receipt preserves that key for subsequent command reads.
Do not delete these artifacts or clear the journal to get past an uncertain result.

A rerun reconciles the original key and bytes, including one same-intent retry
when the command is unknown. A committed receipt permits reads only, never a new
report. An unrelated retained intent, missing original bytes or an existing case
requires inspection rather than generating a replacement key. Cleanup logs out
only the test session and never clears an uncertain domain intent.

Success requires a committed owned command, fresh `pending_review` detail, one
`reported` event, unchanged original/current custody, no hold, no recovery grant,
and private PDF download identical to the uploaded bytes and SHA-256. The private
receipt contains the issue ID/reference for the independent web reviewer. Those
identifiers and proof files remain outside Git.

This checks native Linux reporting and Azure evidence transport. Lost responses
remain fault-tested by the isolated local runner; the live check does not
deliberately interrupt Azure writes. Web review/authorization, actual hub receipt
and physical Android behavior retain their separate acceptance rows.

For ordinary PC phone-frame review with real Azure login:

```sh
flutter run -d linux --debug --dart-define=DEVICE_PREVIEW=true --dart-define-from-file=.env.geoapify.json
```
