# Notifications acceptance

## Open the ordinary client

From the Rider Mobile repository root, the phone frame on Linux uses:

```sh
flutter run -d linux --debug --dart-define=DEVICE_PREVIEW=true --dart-define-from-file=.env.geoapify.json
```

Sign in through the normal Azure account flow, then open **Home → Notifications**.
Refresh, load more, open a notice and follow an available current task or read-only
record. Notice selection does not save read state. Read controls remain disabled
until the separate deployed notification read gate is accepted; the local
automated/kernel tests exercise those writes with isolated data. Device Preview
checks layouts; actual Android behavior has its own acceptance below.

## Selected local checks

- Exact UUID/task/account IDs, integer-cent money, UTC/PHT, nullable copy and
  unknown events; malformed pages fail instead of becoming empty success.
- All-owned unread count is independent of loaded rows. Bounded pagination
  deduplicates shifted pages and reports errors while retaining available rows.
- Single reads send `{}`; bulk reads send 1–50 distinct canonical displayed IDs.
  New same-tick arrivals and offscreen cached rows remain unread.
- Save before POST; storage failure prevents dispatch. Duplicate taps,
  uncertain/replayed/conflicting/expired/foreign reads retain truthful state.
  Restart/lookup/retry keeps the original command UUID and request shape.
- Work, Messages and Notifications journals cannot consume each other's commands
  or expose another account/API. No operational command is introduced by reading.
- Known destinations fetch an exact allowlisted native path. Foreign/changed
  resources, substituted IDs, unknown/null links and late target responses fail
  safely. Task navigation retains the existing Stop Mode authorization checks.
- Background, hidden routes, sign-out/account change and capability loss clear
  private state and cancel pending reads. Resume revalidates without a new loop.
- Real bundled fonts at narrow phone, ordinary phone, landscape, large text and
  desktop sizes; named native buttons, 48dp targets, keyboard Enter and Back.
- Analysis, relevant/full tests and ordinary Linux/Android debug builds.

## Separate external acceptance

- [ ] Approved isolated Azure rider, fresh operations v1 token/notification ability
  and deployed notification/command schema.
- [ ] Real durable event and retry delivery; record deployed scheduler/worker
  configuration without placing mail or account credentials in evidence.
- [ ] Owning website agrees with the exact native displayed reads; a later unseen
  arrival, foreign ID and revoked task link behave correctly.
- [ ] Actual Android Back, screen reader, foreground/background/resume and account
  change checks. Desktop renders and native builds do not establish these.

Keep these requests with earlier parcel/Trips and Messages acceptance. Do not
repeat an accepted production claim or manufacture a real event to fill a test.
