# Pull request draft

Title: Fix rider delivery guidance and recovery access

## Description

Delivery success previously always told the rider to wait for buyer confirmation,
even when the server had already completed a version-two order. The app now
shows the committed order status, retains older uncompleted orders honestly and
keeps COD hub receipt, ledger earnings and actual payout distinct. Stop refresh
also checks changes to the order's commercial status.

Forgot password now opens the actual first-party recovery page. Compact Settings
links to login activity/session controls, login and Help expose restricted custody
recovery, and pending cash offers link to authorized website review/cancellation.
All browser handoffs use a separate website session without passing app tokens.

Android builds use a 1 GB Gradle heap, one worker and no persistent build daemon.
The UI keeps ordinary real-account entry and existing independent write gates.
The Wallet retained-proof/recipient and version-two handover source fixes are on
Bagoo branch `fix/rider-wallet-trip-evidence`; the native prepaid consumer check
passed against its pinned revision. Merge/deploy and controlled live acceptance
remain separate, and the user has deferred phone testing.

## Validation

At Rider source revision `f9dd4cf`, analysis is clean and the serial Flutter
suite passed 693 tests with 7 skips. Configured Linux and Android debug builds
passed sequentially with limited compile workers. Full local results and
remaining acceptance are recorded in [VERIFICATION.md](VERIFICATION.md).
The Rider branch and its commits are pushed. This file remains a PR draft; no
pull request has been opened.
