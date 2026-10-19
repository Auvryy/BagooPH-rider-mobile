# Isolated native notification verification

The existing test bridge has a selected notification suite:

```sh
node tool/parcel_local_api/run.mjs ../bagoo notifications
```

Use a private virtual Linux display to keep the native test window away from an
active desktop. Where Xvfb's helper is installed:

```sh
xvfb-run -a node tool/parcel_local_api/run.mjs ../bagoo notifications
```

Requirements and isolation are in the [shared runner](../../../tool/parcel_local_api/README.md).
The backend checkout stays read only. A fixed committed snapshot runs unchanged
Laravel routes, authentication, command retention and notification services with
SQLite `:memory:` and disposable storage/caches. The fixture has no Azure data.

A synthetic rider turns on duty and claims one isolated pickup through native
commands to create a genuine assignment notice. Labelled software-test outbox
events exercise recipient/source uniqueness, same-tick later arrival and exact
read IDs. The real native session and secure notification journal verify:

- single `{}` and bulk exact IDs, saved once by the actual backend;
- response loss after commit, retained lookup, same-key replay/conflict and
  controlled test expiry without deleting original command rows;
- response loss before dispatch, `COMMAND_UNKNOWN` and explicit same-key retry;
- foreign read rejection and freshly authorized task resolution;
- server rows/counts agree and parcel custody/cash facts stay unchanged by reads.

Native requests are spaced 2.3 seconds apart. The ordinary server/request limits
stay enabled. A short frozen fixture clock is released after same-tick and expiry
assertions so rate-limit windows continue with real elapsed time. Test teardown
clears only its scoped native journals and revokes its synthetic sessions.

This establishes local native-client/backend compatibility. It does not establish
Azure scheduling, browser rendering or physical Android behavior. Ordinary Linux
and Android builds must follow native tests so the normal entrypoint keeps real
Azure login. Deployed acceptance is tracked in the [API checklist](../../api/NOTIFICATIONS_NEEDS.md).
