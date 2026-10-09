# Dashboard/navigation implementation evidence

## Live-data phase

Implemented accepted v1 Home/queues/detail decoding, account discovery, transport
command headers and safe error codes/request IDs. Duty/claim writes persist their
original UUID intent before dispatch; timeout/restart retains it and reconciles.
Reads require discovered version 1 and current approved identity. Production
writes additionally require an accepted-deployment build configuration.

Seven operations contract tests and eight existing workspace controller tests pass.
They check exact IDs/cents, coordinates/privacy, pagination, persist-before-send,
timeout/restart/replay, unknown/expired commands, missing storage, deployment and
account gates, claim body and fresh owned detail. Full existing/local Flutter suite: 107 tests pass with one expected explicit-configuration skip. Analysis is clean. Native builds and later-phase checks will be recorded after implementation.

## External acceptance outstanding

- Actual Azure deployed revision and migration status, including rider_commands.
- Fresh approved rider bearer/version/Home/queues/detail and denied access checks.
- Authorized duty/claim reflected in the owning website, stale/competing claim
  and uncertain-response recovery through the native client.
- Dedicated Geoapify client key and real-provider route/quota checks.
- Physical Android precise/notification denial, screen-off/minimized updates,
  stop/resume, permission removal, reassignment and authorization revocation.

No Azure operational mutation or physical navigation acceptance is claimed.
