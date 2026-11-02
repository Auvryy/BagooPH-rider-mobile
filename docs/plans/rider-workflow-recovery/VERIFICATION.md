# Local verification

November 1, 2026. Client scope: delivery completion/earnings guidance, specific
website recovery access and bounded build resources. The Rider source baseline
was `4367331`; the backend reference stays read-only at `f001d39`.

## Selected-slice local results

These initial results describe the implementation handoff. A newer branch-head
recheck is recorded at the end of this file.

| Check | Result |
|---|---|
| `flutter analyze --no-pub` | Passed; no issues. |
| `flutter test --no-pub --concurrency=1 --reporter=json` | 691 passed, six expected skips; runner exit zero. |
| Earnings footer regression | Both available/unavailable cases passed; pending polling timers are cleaned up by the test harness. |
| Configured Linux debug build | Passed, including the PC phone frame. Native compilation uses a single Ninja job during verification. |
| Configured Android debug build | Passed with the limited Gradle configuration; `app-debug.apk` produced. |
| Documentation and Git scope | Relative links, explicit changed-file privacy and whitespace checks pass; the local operating guide stays ignored and untracked. |

The six skips retain opt-in historical rendering/benchmark/configuration work
and the separately invoked company integration case. This delivery did not
rerun that native-to-kernel company suite or certify a new deployed session.

State tests cover committed completed/delivered/unknown outcomes, retained
recovery instructions and changed commercial status invalidating a reviewed
stop. The committed result is described without assuming a later receipt;
historical Delivered results direct the rider to refresh current Trips.

UI tests exercise available/unavailable earnings, trusted fixed recovery URLs,
no account/credential query parameters, a failed website launch, 320px doubled
text and unchanged first-screen Settings controls. Password recovery no longer
passes by opening a placeholder explanation. Existing tests caught Settings
growth; the security link now sits in its compact account group.

Builds and checks are sequential. Android uses a 1 GB Gradle heap, 512 MB maximum
metaspace, one worker, disabled parallel tasks, no persistent build daemon and
in-process Kotlin compilation. The heap limit is not a claim that all build
processes together consume at most 1 GB.

## Assessment and remaining limits

| Client behavior | Before | Verified result |
|---|---|---|
| Delivery/earnings guidance | Unconditional buyer-confirmation and unavailable-earnings copy contradicted recorded results. | Committed completion, cash and earnings are distinct across task/result/history views. |
| Recovery access | Password recovery opened a placeholder; relevant security and recovery destinations were missing. | Fixed first-party password, sessions, cash and custody destinations are reachable, including failed-launch handling. |

These results cover the selected client behavior, not whole-system readiness or
deployed delivery acceptance. Website sign-in/revocation and physical lifecycle
checks remain separate. No endpoint, assignment, cash
record, approval, order status or production setting was changed by this client.

All independent operational write gates are unchanged. The user explicitly
deferred phone testing while another mobile project uses the device. The
[remaining backend needs](BACKEND_NEEDS.md) and [rehearsal](REHEARSAL.md) stay open.
No physical camera/GPS, release signing, closed-app push, live routing, deployed
Wallet proof acceptance or full cross-role live success is claimed.

## Local handoff

- `9b2d888` — show recorded delivery completion and earnings.
- `aa76171` — open account and cash recovery workflows.
- `ebb6992` — limit Gradle memory and parallel workers.
- At the time this record was first written, the branch had not been pushed; see
  the later source follow-up below and the [PR draft](PULL_REQUEST.md).

From the rider repository:

```sh
flutter run -d linux --debug --dart-define=DEVICE_PREVIEW=true --dart-define-from-file=.env.rider.json
```

## November 1 source and mobile consumer follow-up

The Wallet retained-proof/recipient and version-two backend findings recorded
above are now fixed in Bagoo branch `fix/rider-wallet-trip-evidence` through
`9e58312d130809eb8cd878189b729f1f702291d8`. Its focused backend run passed 452
tests and 16,115 assertions. The Rider's pinned native prepaid integration test
passed against that source: one replayed paid Wallet delivery, completed order,
one immutable receipt, no COD, and the original recipient plus exact original
private proof bytes in Trips. The PHP kernel was isolated with SQLite `:memory:`
and no network.

This resolves the local source/client gap only. The write gates remain false,
and the user deferred physical phone testing. Bagoo PR #144 later merged the
source into `main` at `9ca5db5`; this does not confirm deployment. The existing
recovery and PC build evidence above does not claim live Azure, cross-role or
Android hardware acceptance.

## Earlier branch-head PC recheck — November 1, 2026

At Rider source revision `f9dd4cf` on `fix/rider-trips-completion-copy`,
`flutter test --no-pub --concurrency=1 --reporter=compact` exited 0 with **693
passed and 7 skipped** in 5 minutes 19 seconds. `flutter analyze --no-pub`
exited 0 with no issues. Both commands ran on the PC; no phone or emulator was
used. That recheck superseded the older full-suite total at the time; it was
later superseded by the published 699-test checkpoint and the local 700-test
regression below. It does not replace the separate Azure, cross-role,
release-signing, or physical Android acceptance gates.

## Published-branch full PC regression and defense APK — November 1, 2026

At Rider test checkout `fc99a02` (runtime change `a9b972d`), the full serial
Flutter suite passed **699 tests with 7 skips and zero failures** in 5m57s:

```sh
flutter test --no-pub --concurrency=1 --reporter=compact test
```

`flutter analyze --no-pub` reported no issues after the theme update. The
published branch later received documentation-only commits, so the tested
runtime and tests are present in its current head. This is PC-only unit/widget
evidence; it does not establish Android hardware, Azure or cross-role
acceptance.

An arm64-targeted debug APK was built at published Rider revision `8b50401`,
using the same runtime code. Its current PC verification reports archive
integrity, package/version/SDK metadata, debuggable state, a one-signer APK v2
signature and SHA-256. It was not installed, and its scaffold package ID/debug
signing do not make it a release artifact. See the
[Android packaging record](../../ANDROID_RELEASE.md) for the build command,
artifact size and full checksum. Physical Android and release-signing gates
remain open.

The isolated company consumer check also passed **1/1** in 50 seconds using
Rider source revision `9886648` against Bagoo commit `9e58312`:

```sh
node tool/parcel_local_api/run.mjs ../bagoo company 9e58312
```

The runner used the committed backend snapshot, SQLite `:memory:` and a
headless Dart client. It verified uncertain-request replay with the original
key, stale-offer rejection, exact acceptance/placement, duty remaining off, and
no delivery checkpoint or COD account. The Bagoo worktree remained read-only;
this check did not contact Azure or use a phone.

## Earlier November 1 PC evidence snapshot

At Rider revision `e0aa20e` on `fix/rider-trips-completion-copy`, the full
serial Flutter suite passed **693 tests with 7 skipped** in 6 minutes 25
seconds. `flutter analyze --no-pub` also passed without issues at this source
revision. These checks used no phone or emulator.

At that earlier snapshot, the arm64-targeted profile APK was built with the
repository's single-worker Gradle settings:

- Output: `build/app/outputs/flutter-apk/app-profile.apk`
- Size: **77,606,440 bytes**
- SHA-256: `74b52c2bc2cdc3fcb965b829bcb9d3ffcbe51e9fef0b3229e5bbde950fafc84b`
- Merged manifest: `com.example.bagoo_rider_mobile`, min SDK 24, target SDK 36,
  version code 1, version name `0.1.0`
- `unzip -t` verified the APK archive. `apksigner verify` could not run because
  Java is not available on the PC shell's PATH; this build's signature was not
  independently verified.
- This is a profile preview using the scaffold package ID and debug signing
  configuration. It was not installed or launched.

A separate PC `--release` build request was also attempted at `e0aa20e`. Gradle
stopped before artifact generation and named the missing approved
`RIDER_APPLICATION_ID` and local keystore settings. The fail-closed result is
verified; no release APK was produced and no signing key was read or used.

At the time of this pre-merge check, live GitHub refs matched Rider `main`
`4367331` and published defense branch `4d4663d`. Local HEAD `e0aa20e` is 28
commits ahead of main and 2 commits ahead of the published branch. Bagoo `main`
matched `f001d396b0e9ea6bfc2fdeb85ee24b66682b997e`; its read-only Wallet/handover branch
`9e58312d130809eb8cd878189b729f1f702291d8` was 2 commits ahead at that time.
PR #144 later merged it into Bagoo `main` at `9ca5db5`. Azure cross-role
acceptance, approved release identity and signing, and physical Android
acceptance remain open.

## Map-disclosure branch-head APK — November 1, 2026

At Rider runtime code revision `9d7e8cf` and test revision `039d40d`, six
focused PC checks passed serially, including the disclosure copy at 320 px and
200% text in both Home and Stop Mode. `flutter analyze --no-pub` reported no
issues. A fresh
arm64-targeted profile APK was built with the repository's single-worker Gradle
settings using the ignored `config/azure.json` file. The build completed in
276.7 seconds.

- Output: `build/app/outputs/flutter-apk/app-profile.apk`
- Size: **77,606,440 bytes**; SHA-256
  `28be6a6645ce7549ee0ad94b4c36491c75cd3fdecc601d7cfabeae689c622d84`
- `aapt dump badging`: package `com.example.bagoo_rider_mobile`, min SDK 24,
  target SDK 36, version code 1, version name `0.1.0`
- Zip archive integrity passed. `apksigner verify` passed with APK Signature
  Scheme v2 and one debug signer. AOT string inspection found both the OSM tile
  notice and the external Google Maps destination notice in `libapp.so`.
- The APK was not installed or launched; this is PC packaging evidence, not
  physical Android acceptance or a release artifact.

The build emitted an SDK XML version warning (the build tools understand XML
version 3 while the installed SDK metadata uses version 4) and completed
successfully. At this map checkpoint, the latest full-suite result then
available was the run at source revision `e0aa20e`; the map-disclosure code
received the six focused checks above, not a full-suite rerun. At the same
checkpoint, the published branch was `e9fb7e3` and Rider `main` remained at
`4367331` (34 commits ahead, 0 behind). No phone or emulator was used.

## Proof recovery and private Trips viewing — November 1, 2026

At Rider source revision `cbd6b21` on `fix/rider-route-privacy-disclosure`,
the following focused PC command passed serially: **20 tests, zero failures**.

```sh
flutter test --no-pub --concurrency=1 \
  test/parcel_photo_recovery_test.dart \
  test/protected_parcel_proof_test.dart \
  test/trips_pages_test.dart
```

The seven photo-service cases cover account/API/task scoping, restart and
simulated lost-picker recovery, expired drafts, cancellation and session
changes. Four proof-store cases cover encrypted, hash-bound retention, account
and API isolation, tamper rejection, and invalid image rejection. Nine Trips
widget cases include doubled-text small-screen layouts, private proof clearing
on background, deliberate reopening after resume, and removing the proof route
on logout. Android lost-file behavior used a simulated picker in PC tests; this
does not verify a physical Android picker, process lifecycle, or secure storage
on a device. No phone or emulator was accessed, and this was not a full-suite
rerun.

## Shared pickup and cash recovery journal — November 1, 2026

The focused cash repository suite passed **14 tests, zero failures** on the PC:

```sh
flutter test --no-pub --concurrency=1 --reporter=compact test/cash_repository_test.dart
```

The added synthetic API case commits a pickup claim and loses its response, then
recreates the repository with a separate secure-journal instance for the same
API origin and rider account. Cash sees the unresolved claim and blocks a new
offer; another account cannot read that intent. Reconciliation checks the
original command key once without resending the claim, clears the shared intent,
and then permits a distinct cash offer. This is a host-side repository test
using mock secure storage and a fixture API. It does not establish deployed
backend behavior, live account acceptance, or Android-device storage behavior.
At this earlier focused-test checkpoint, the latest full-suite total was the
699-test result above; the full suite was rerun later at `d04cb54` below.

## Earlier full PC regression — November 1, 2026

At local Rider test head `d04cb54` on `fix/rider-route-privacy-disclosure`, the
full serial Flutter suite passed **700 tests with 7 skips and zero failures** in
4m26s:

```sh
flutter test --no-pub --concurrency=1 --reporter=compact test
```

`flutter analyze --no-pub` reported no issues in 7.8s. The run used one worker
and no phone, ADB, emulator, install, or app window. Runtime code remains
`a9b972d`; changes since then are documentation and tests. The test head is not
pushed. These results do not establish Azure deployment, release signing,
cross-role live acceptance, or physical Android behavior.

## Doorstep Guide and defense regression — November 2, 2026

At Rider branch commit `f0de3a2` (current runtime code `daacf85`), the complete
serial Flutter suite passed **715 tests, 8 skipped, zero failures** in 5m14s
with one worker:

```sh
flutter test --no-pub --concurrency=1 --reporter=compact test
```

The focused Home and Stop Mode test files passed **46/46**, including the
supplied and missing saved-instruction states. `flutter analyze --no-pub` found
no issues at runtime revision `daacf85`. A current arm64 debug APK was built
from that same runtime source. It is 176,228,861 bytes, SHA-256
`215a1275cc6e4b83a7dce8a39e3d5a493cdecfd9391f91d1114e61af139e6d61`; its ZIP,
package/SDK metadata, ARM64 Flutter engine, manifest permissions and
single-signer APK v2 signature passed PC checks. It was not installed or
launched. The APK uses the scaffold application ID and Android Debug signing,
so it is not a distributable release build. A fresh Linux Device Preview debug
build from the same source also passed with one Ninja job; it was not launched.
It supports a PC layout walkthrough only and uses a different map renderer from
Android. The PC build command was:

```sh
CMAKE_BUILD_PARALLEL_LEVEL=1 flutter build linux --no-pub --debug \
  --dart-define=DEVICE_PREVIEW=true \
  --dart-define-from-file=.env.rider.json
```

No phone, ADB, emulator or app window was used. Azure deployment,
cross-role live acceptance, approved release signing and physical Android
acceptance remain open. See the
[current rehearsal](REHEARSAL.md) and [Android artifact record](../../ANDROID_RELEASE.md).
