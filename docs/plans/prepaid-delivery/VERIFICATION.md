# Paid Wallet delivery verification

October 22, 2026. Rider base `9806ce5`; backend snapshot
`99e5895f98159334e372df4f43659fda0bd43960`, inspected without modifying its
checkout. This record separates implemented client behavior from backend and
operational acceptance.

## Native compatibility and concrete gaps

The real Linux Flutter client ran against the isolated Laravel HTTP kernel using
SQLite `:memory:`. The owning buyer paid an actual synthetic Wallet order;
ordinary hub workflows assigned its final mile. The native rider departed and
delivered using recipient, relationship and original image, with no cash fields.

- One delivery command, one delivered checkpoint and one immutable Wallet
  handover receipt persisted. No COD account was created.
- A deliberately lost response retained the original protected intent/image.
  A new repository reconciled the committed result. The exact original UUID,
  body and image replayed successfully without a second outcome or receipt.
- Order state was `delivered`, payment remained `paid`, and buyer completion
  was not performed.
- Retained Trips returned the Wallet assignment and a proof link, but that
  authenticated proof request returned **404**, and original recipient was null.
  Source inspection confirms COD-only evidence lookup in `RiderTripService`.
- The diagnostic scenario passed in 37 seconds after compilation. That exit
  verifies reproduction and handoff/replay compatibility; it does not accept
  retained Wallet proof or recipient behavior.

The isolated runtime was removed on exit. The virtual display was separate from
the active desktop. No Azure command, production parcel, real account or map
provider request was involved.

## Client and build checks

- Clean `flutter analyze --no-pub`.
- **45 selected checks passed**, including paid cash omission, independent
  activation, legacy COD journal safety, original proof/UUID recovery, changed
  payment review without a version change, honest retained history and forms at
  320/840 logical pixels with 200% text.
- **605 full Flutter tests passed, five expected skips**, exit 0. The command
  completed in 3 minutes 23 seconds. The optional native/Azure probes were not
  treated as live acceptance.
- The prepaid form and retained Wallet history renders were visually inspected.
  Ordinary scrolling keeps large text usable, and no cash inputs appear for an
  eligible paid task. A payment-change test caught ancestor Form notification
  during build; review reset now blocks readiness and clears fields after the
  frame. The corrected full suite passed.
- Ordinary **Linux debug and Android debug APK builds passed** with the normal
  Azure account entrypoint and existing private map configuration. These builds
  do not enable parcel or prepaid writes.
- PHP/Node runner syntax, changed Markdown links, staged privacy and diff checks
  passed. The read-only backend remained clean at the reviewed revision.

The native diagnostic above is additional to the Flutter unit/widget total.
No physical Android test or deployed prepaid acceptance is claimed.

## Outstanding acceptance at the October 22 baseline

The following rows describe the state at the time of the original verification
above; the November 1 follow-up below records the later source repair.

- The original Wallet proof/recipient source defect needed an owner fix and
  native compatibility against the fixed source.
- Azure deployment/migrations, fresh discovery and designated sequential COD
  and paid Wallet acceptance remain open.
- Physical Android camera, permissions, picker recovery and interruption checks
  remain open.

At that point both parcel and prepaid write gates remained default-false.
Existing local duty/claim acceptance and private map configuration were
unchanged. The [API checklist](../../api/PREPAID_DELIVERY_NEEDS.md) now records
the source follow-up and the remaining deployment/live gates.

## November 1 source repair and native reacceptance

The original section above preserves the October 22 baseline, where the native
runner reproduced the Wallet recipient/proof defect. Bagoo later fixed that
source behavior on `fix/rider-wallet-trip-evidence` through
`9e58312d130809eb8cd878189b729f1f702291d8`; its focused backend suite passed
452 tests and 16,115 assertions. The backend regressions include mismatched
receipt identity, missing or changed proof, foreign access and a reassigned
delivery.

On November 1 the Rider Linux integration test passed against that pinned
revision. The client simulated a lost delivery response, reconciled it, replayed
the original UUID/body/image and received one completed paid Wallet result. Trips
returned the original recipient and the exact original private image; its
SHA-256 matched both the uploaded bytes and immutable receipt. The fixture
recorded one delivery command, one Wallet receipt and zero COD accounts. The
isolated PHP kernel used SQLite `:memory:` and no network. The native Linux test
ran on the PC; Android hardware and Azure were not involved.

This closes the local source/client compatibility gap. Both the native prepaid
write gate and the general parcel write gate remain false. The source branch is
not merged or confirmed deployed, and controlled Azure, cross-role and physical
Android acceptance remain open.

## November 2 windowless Rider client recheck

Rider commit `87244ed5a66d347792bc37b412bd28b3d3a23159` adds a headless runner
for the same shared Wallet client scenario. It passed **1/1** in 35 seconds
against Bagoo commit `9e58312d130809eb8cd878189b729f1f702291d8`:

```sh
node tool/parcel_local_api/run.mjs ../bagoo prepaid-headless \
  9e58312d130809eb8cd878189b729f1f702291d8
```

The isolated SQLite `:memory:` Laravel kernel exercised the real Rider
repository and Dio API client without a desktop window or connected phone. A
mock secure-storage adapter held the command journal; the scenario verified
lost-response reconciliation, exact UUID/body/proof replay, one completed paid
order, one Wallet receipt, zero COD accounts, and the original recipient plus
hash-matched private proof from Trips. The result records
`prepaid_live_accepted=false`. This check does not exercise the platform
storage plugin, Azure, live writes, or physical Android behavior; the separate
Linux integration path still uses the platform secure-storage plugin. The
Bagoo worktree was read-only.
