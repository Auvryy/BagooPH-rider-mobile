# Messages acceptance

## Local contract and command checks

- [ ] Exact 64-bit identifiers, phase/assignment/participant identity, nullable
  preview/avatar, UTC timestamps, newest-first pages and stable deduplication.
- [ ] Plain text normalization/validation; denied, missing and stale capabilities.
- [ ] Protect intent before dispatch; storage failure prevents a write. Duplicate
  taps, lost response/restart, same-key retry, retained committed/expired results,
  changed payload and account isolation preserve the original intent.
- [ ] Conversation/history errors retain safe known data. Superseded requests,
  changed recipient and account/access loss cannot restore stale private state.
- [ ] Only a selected rendered incoming boundary reads; new unseen arrivals,
  unopened threads, background/offstage and obsolete render callbacks do not.
- [ ] Pagination, foreground polling, shared budget/429 cooldown and resume
  reauthorization work without fabricating unread totals or sent messages.

## Layout and native checks

- [ ] Small phone, landscape, desktop, 200% text, reduced motion, keyboard/Back,
  loading/empty/error/read-only/recovery states and accessible 48dp controls.
- [ ] Stop shortcut resolves only fresh owned phase-bound threads.
- [ ] Analysis, selected/full Flutter tests, ordinary Linux/Android builds.
- [ ] Native Linux client uses an isolated real backend kernel for seller/buyer
  identity, send/read replay, late unread arrival and foreign/stale rejection.

## Separate external acceptance

- [ ] API owner confirms actual Azure deployed revision and completed migrations.
- [ ] A fresh authorized native session advertises v1 and messaging capability.
- [ ] Isolated seller pickup and buyer final-mile threads agree with owning web
  views; each deliberate send appears once and unseen messages remain unread.
- [ ] Controlled reassignment/phase/participant and foreign-boundary checks deny
  the obsolete thread without rerouting its draft.
- [ ] Physical Android keyboard, Back, background/resume, account changes and
  protected intent restoration are observed on a connected phone.

Keep the messaging write switch disabled until the relevant deployment/session
gate is recorded. Do not repeat previously accepted parcel claims to create chat
fixtures. Missing session, simulated replies and APK compilation are not live
chat acceptance.
