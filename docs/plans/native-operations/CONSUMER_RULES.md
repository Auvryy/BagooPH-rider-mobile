# Shared consumer foundation

These are integration constraints, not a second wire specification. The
[backend contract](SOURCE_REVIEW.md) owns exact fields, units, enums and validation.
Complete or verify this foundation before the selected write slice.

## Access and decoding

- Reuse `RiderApiClient`, the existing `RiderSessionApi`/secure-token boundary and
  account/Settings integration. HTTPS bearer requests stay on the first-party
  `/api/v1` origin; browser cookies/Inertia HTML are not operational data.
- Discover version and Home capabilities after fresh login. New abilities are
  `rider:operations:read`, `:work`, `:messages`, `:notifications` and `:cash` under
  that same prefix. An old restored token may require sign-in again; never force
  capabilities true or disable ordinary account access when operations are absent.
- Preserve IDs as strings, including positive decimal IDs through signed 64-bit
  maximum and phase/trip/thread references. Keep nulls and unknown status codes
  honest; commands use server action hints/denial reasons and revalidate on write.
- Response money is exact integer-cent strings, including signed journal values
  where specified. Peso input is an exact decimal string with at most nine whole
  digits and two decimal places. Do not use binary floats or the old generic
  proposal's numeric `minor_units` shape.
- Parcel/claim `expected_version` is an opaque 64-character lowercase hex string.
  **Cash-offer `expected_version` is a journal-sequence ID-range string.** Duty,
  message and read bodies have their own required fields; do not attach a blanket
  version field to every request or parse all versions as the same type.

## One durable intent per write

1. Create a lowercase UUID `Idempotency-Key` for each genuine write, including
   duty, claims, physical outcomes, messages, displayed reads and cash offers.
   `X-Request-ID` is separate request correlation.
2. Persist the account/intent identity, exact action/resource/body and key before
   dispatch. Keep a single unresolved intent through timeout/restart; disable
   duplicate submission. Version and participant references remain the original
   ones. New user intent must be an explicit decision after reconciling the old one.
3. After an uncertain result, call `GET rider/commands/{key}` with the same owner,
   then refresh the affected resource/history. `COMMAND_UNKNOWN` can mean an
   uncommitted transaction; it proves neither failure nor permission for a new key.
4. Retry only the same key, payload and **original proof bytes**. Compression,
   recapture, a changed recipient or amount changes the intent. Same-intent replay
   returns the original result; conflicts/expired writes require explicit recovery.
5. Respect the seven-day replay window. Reconciliation still exposes retained
   results and `retry_expired`; do not reset a key to bypass expiry or stale state.

The protected journal must stay account-scoped across restart/reauthentication.
Clear visible resources, credentials and stale drafts immediately on account or
access changes. Define protected retention/deletion for unresolved intents and
proof before implementing their storage: no cross-account exposure and no silent
loss of original bytes needed to reconcile/retry. This is recovery metadata,
not an offline-success queue. Tokens, contacts and proof must not enter logs/docs.

## Resource states and refresh

- Distinguish unavailable/denied, empty, stale, refreshing, failed and uncertain.
  A tap, animation, upload selection or mock response is not committed work.
- On confirmed action and app resume, refresh authoritative resources. Foreground
  refresh starts at 30 seconds; pause in background, share polling and honour
  cooldowns. The native v1 budget is 30 requests/minute plus a 10/minute write
  budget; do not poll every component independently.
- Lists default 20/max 50; pages are bounded to 10,000. Refresh page one and
  deduplicate by server reference: offset pages are not a frozen snapshot.
- Handle 401 session loss, 403 denied ability/account, 404 hidden resource,
  409 stale/intent/domain conflict, 422 fields, 429 numeric Retry-After and
  503 unavailable schema/service. Preserve safe request IDs for diagnosis.
- After reassignment or a terminal outcome, refresh/reconcile instead of granting
  an action from a cached status. Off duty preserves existing responsibilities.

Keep feature decoding/repositories/controllers separate from widgets. Unit tests
can use owner fixtures, but live acceptance and physical-device checks must record
real authorized behavior. Unsupported release/recovery/earnings remain unavailable.
