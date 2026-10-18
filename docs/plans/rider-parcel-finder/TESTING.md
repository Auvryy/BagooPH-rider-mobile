# Parcel Finder checks

- [ ] Two owned parcels may share a slot; changing selection never transfers it.
- [ ] Exact account/API/task/assignment identity is preserved, including large IDs.
- [ ] Ordinary refresh and queue switching preserve labels; partial-page absence
  does not clear them. A complete owned queue may remove absent responsibilities.
- [ ] Preview, absent assignment, denied/stale reads, changed assignment and
  terminal responsibility cannot save or retain a misleading location.
- [ ] Logout/account/API changes and disposal clear session labels. Background,
  covering routes and late reads cannot apply an obsolete edit.
- [ ] Label editing sends only the existing authorization GET; no parcel command,
  journal, private file, location history or server label is created.
- [ ] Full tracking remains visible, suffix collisions remain distinguishable,
  and wrong waybills still fail the original scan checks.
- [ ] Ordinary scrolling, Back, keyboard focus, 48dp controls, 200% text and
  small-phone/landscape/desktop layouts work with reduced motion.
- [ ] Analysis, relevant/full Flutter regressions and ordinary Linux/Android
  builds pass; actual renders are inspected.
- [ ] Evidence and the cumulative external checklist are updated without
  declaring unrelated Azure or physical Android acceptance complete.

## PC phone view

From the Rider Mobile repository root:

```sh
flutter run -d linux --debug --dart-define=DEVICE_PREVIEW=true --dart-define-from-file=.env.geoapify.json
```

Use real Azure login privately. Open a currently owned task, then **Work this
stop** and **Parcel Finder**. Available pickup previews cannot set a label.
The native app contains no sample login or fabricated held parcel. Layout
review does not establish actual Android touch or deployed custody acceptance.
