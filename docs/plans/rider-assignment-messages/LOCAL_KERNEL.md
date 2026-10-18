# Isolated native Messages verification

From the Rider repository root, the existing kernel runner has a selected
Messages mode:

```sh
node tool/parcel_local_api/run.mjs ../bagoo messages
```

Use an available virtual Linux display to keep the native test window away from
an active desktop, for example `xvfb-run -a` where that command is installed.
Requirements and isolation are documented in the
[shared runner](../../../tool/parcel_local_api/README.md).

The runner snapshots the backend's committed revision without changing its active
branch or including another developer's uncommitted files. Its database is
SQLite `:memory:` and its files/caches live in a disposable ignored sandbox.
A fresh synthetic rider performs explicit local duty/claim/collection; actual
hub intake closes seller sending, then owning domain workflows prepare the
sequential buyer assignment. No production account or parcel is used.

The real native Dio/session and secure message journal exercise seller and buyer
threads, late unread arrival, original-key replay after a lost response, unknown
read recovery, read-only phase, foreign thread/boundary rejection and exactly one
message per intended send. Replies use the owning seller/buyer Chat action;
read-only owning web inbox payloads and saved rows independently check parity.
The separate web history endpoint that marks messages read is not called.
Normal request/write limits remain enabled with 2.3-second native request spacing.

This is local compatibility evidence. It does not prove Azure deployment,
physical Android typing/lifecycle or the website's browser rendering. Rebuild the
ordinary app after integration tests before handing a Linux bundle or APK to the
user; the ordinary entrypoint must retain real Azure account access.
