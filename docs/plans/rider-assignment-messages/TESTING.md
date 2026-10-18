# Messages acceptance

## Local contract and command checks

- [x] Exact 64-bit identifiers, phase/assignment/participant identity, nullable
  preview/avatar, UTC timestamps, newest-first pages and stable deduplication.
- [x] Plain text normalization/validation; denied, missing and stale capabilities.
- [x] Protect intent before dispatch; storage failure prevents a write. Duplicate
  taps, lost response/restart, same-key retry, retained committed/expired results,
  changed payload and account isolation preserve the original intent.
- [x] Conversation/history errors retain safe known data. Superseded requests,
  changed recipient and account/access loss cannot restore stale private state.
  Explicit denial removes that thread's draft, history and inbox preview, and
  cancels older inbox pages so they cannot restore the denied preview.
- [x] Only a selected rendered incoming boundary reads; new unseen arrivals,
  unopened threads, background/offstage and obsolete render callbacks do not.
- [x] Pagination, foreground polling, shared budget/429 cooldown and resume
  reauthorization work without fabricating unread totals or sent messages.

## Layout and native checks

- [x] Small phone, landscape, desktop, 200% text, reduced motion, simulated
  keyboard inset and widget Back navigation,
  loading/empty/error/read-only/recovery states and accessible 48dp controls.
- [x] Stop shortcut resolves only fresh owned phase-bound threads.
- [x] Analysis, selected/full Flutter tests, ordinary Linux/Android builds.
- [x] Native Linux client uses an isolated real backend kernel for seller/buyer
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

## PC phone-frame review

From the Rider Mobile repository root, with the existing ignored map
configuration:

```sh
flutter run -d linux --debug --dart-define=DEVICE_PREVIEW=true --dart-define-from-file=.env.geoapify.json
```

This opens the ordinary Azure-connected app inside a phone layout frame. Sign in
privately; chat availability still depends on the returned capability. Layout
review does not complete physical Android or live sending acceptance.
