# Isolated native handover verification

From the Rider repository root:

```sh
node tool/handover_local_api/run.mjs ../bagoo
```

Requires the reviewed backend checkout with its Composer development dependencies,
PHP with `pdo_sqlite`, Node 22 or newer, and the existing Flutter/Linux toolchain.
It adds no package dependency and does not require credentials, a provider key,
an Android phone or a running backend container.

The runner starts a single Laravel test application using the backend's existing
handover and order-flow test helpers. Before migrations, it removes all database
connections except SQLite `:memory:`. Evidence, storage and cache paths use an
isolated directory inside ignored `build/handover-verification/`; that directory
is removed when the runner exits. The backend checkout remains unchanged.

The native Flutter test sends real Dio HTTP requests to a loopback-only bridge.
Node's standard Fetch parser decodes multipart fields/files; the unchanged
Laravel HTTP kernel, middleware, validators and services handle the requests.
JSON booleans, command headers, original file bytes, response headers and private
document bytes cross that boundary. This exercises neither PHP's web-server
multipart parser nor a deployed proxy's upload limits.

A random local fixture token protects synthetic setup/review/receiving controls.
Those controls are part of this runner only, outside the Rider API and ordinary
application. They reuse the backend's owning-role test actions. No live account,
parcel, custody record or production write switch is involved.

The test checks original PNG/PDF bytes, encrypted intent retention, lost committed
responses, unknown-command retry with the same intent, real field rejection,
observations that preserve stock/custody/cash, one holder event and a retained
hold until the fixture's web actor records receipt. Physical possession and
actual hub receipt remain separate live acceptance.

Normal runs skip `integration_test/handover_local_api_test.dart` unless the local
runner supplies both loopback configuration and its ephemeral fixture token.
The diagnostic log is ignored and private; only synthetic test data is used.
Existing Azure/Geoapify configuration and ordinary app startup are untouched.
