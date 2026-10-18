# Isolated native pickup, delivery and Trips verification

From the Rider repository root, with the reviewed backend checkout alongside it:

```sh
node tool/parcel_local_api/run.mjs ../bagoo
```

The selected Messages suite reuses this bridge and isolation:

```sh
node tool/parcel_local_api/run.mjs ../bagoo messages
```

Its [acceptance notes](../../docs/plans/rider-assignment-messages/LOCAL_KERNEL.md)
cover actual seller/buyer replies, exact read boundaries and retained commands.

Requires Composer development dependencies in that backend, PHP with `pdo_sqlite`,
Node 22 or newer and the Flutter/Linux toolchain. A Linux display and native
secret service are needed for the native runner. A virtual display keeps the
test window away from the active desktop; where `xvfb-run` is available:

```sh
xvfb-run -a node tool/parcel_local_api/run.mjs ../bagoo
```

The backend checkout is read-only. The runner archives a fixed committed revision
and binds copied Composer metadata to that snapshot; installed dependency
packages are read-only references. It does not switch the website's active branch.
Before migration, the fixture restricts
database connections to SQLite `:memory:`. Runtime caches and proof files live
in an isolated ignored build directory, removed on exit. Login accounts, orders,
waybills and images are synthetic. No Azure endpoint, live account, map key or
production write switch is used. The test skips without both loopback
configuration and its ephemeral fixture-control token.

Flutter uses real Dio requests, native protected command metadata and encrypted
original proof files. The loopback bridge uses Node's standard multipart parser
and the unchanged Laravel HTTP kernel, authentication, validators and services.
It captures the real private file/stream response and headers. It does not test
PHP's deployed multipart parser, a proxy's upload limits or Android hardware.
Laravel's standard `withoutVite` test helper omits frontend asset tags; this is
a native/API and owning-action check, not a website asset-build check.

The fixture prepares work sequentially, preserving the same assigned hub and
honouring active-work and duty eligibility. Pickup claim/collection, hub intake,
final-mile departure, recipient/COD delivery, buyer receipt, failure and actual
hub return each use their owning native or web workflow. Retained history and
private proof are checked after an authorized retry is assigned to another rider.
Lost responses and same-key recovery must leave one outcome and collection.
Another rider cannot read the original assignment's private evidence, and
changed proof is rejected. The normal request limiter stays active.

These checks establish local native/client-to-backend compatibility. Live Azure
acceptance and physical Android scan, permissions and picker recovery remain
required in the [selected plan](../../docs/plans/rider-orders-delivery-trips/README.md).
