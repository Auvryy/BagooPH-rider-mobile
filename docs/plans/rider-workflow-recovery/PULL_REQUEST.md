# Pull request draft

**Title:** Prepare Rider guidance, privacy and recovery for defense

## Description

The Rider app shows the server-recorded delivery and order state, keeps COD
handover and earnings separate, and opens the existing first-party account,
restricted-custody and pending-cash recovery pages. The Doorstep Guide displays
the saved buyer instruction for an authorized final-mile stop.

Photo recovery clears plaintext from memory on backgrounding and removes
inappropriate drafts on access loss.
An app-level cover hides the Rider interface while inactive, and Android sets
`FLAG_SECURE` while paused. Map and external-direction disclosures describe the
actual data shared. The default build does not enable device location or route
following. The onboarding buttons use the bundled Rider typeface.

Android release packaging requires an approved application ID and signing key.
A separate restricted debug setting disables platform cleartext traffic for
the defense APK; ordinary debug builds retain their local-development setting.
The Rider API configuration also rejects origins without a host. Existing
independent operational write gates remain in place.

## Validation

- At Rider commit `74a30fc`, the full serial PC suite passed **719 tests with
  9 skips**. Static analysis at documentation-only head `1f00aac` found no
  issues. The opt-in defense-profile check passed separately.
- The arm64 restricted debug APK built from `422a02c` passed archive,
  package/SDK, architecture, manifest and debug-signature checks. It was not
  installed and uses a scaffold application ID and Android Debug signer.
- The local Wallet client scenario passed against Bagoo source `9e58312` with
  an in-memory secure-storage adapter. The corresponding web fixes remain on
  `fix/rider-wallet-trip-evidence`; deployment and live acceptance are separate.

The exact APK hash and build settings are in [Android packaging](../../ANDROID_RELEASE.md);
the [rehearsal](REHEARSAL.md) records the evidence and remaining gates. Physical
Android behavior, deployed cross-role workflows, approved release identity and
signing remain unverified. The desktop preview is a normal sign-in flow, not an
automatic sample workspace.

## Branch status

The Rider feature branch is published and includes GitHub `main` at `4367331`.
This document is a draft PR description; GitHub PR status has not been verified.
