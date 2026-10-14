# Selected map acceptance

## Local implementation

- [x] Licensed asset/provenance and reproducible derivation retain all source
  islands and coordinate order; malformed/missing geometry fails clearly.
- [x] PH overview and bounds/mask work at phone/tablet widths, rotation and
  supported zooms. Nearby foreign land stays masked; real stop points stay unchanged.
- [x] Active route outranks selection/queue; selected stops stay pinned after
  filtering. Missing/outside-outline stops retain address/directions fallback.
- [x] Pan/Recenter, hidden/mapless Home, keyboard, 200% text, account/task access
  changes and the existing navigation limits remain covered.
- [x] Clearer standard-density default and any density choice use separate cache/
  image keys, one request per tile, bounded retries and existing bearer isolation.
- [x] Provider samples, asset/render checks, relevant/full tests, analysis and
  ordinary configured Linux/Android builds have concrete evidence.
- [x] Scope/privacy, docs/links and coherent local commits reviewed; publication
  belongs to the user. No later HDB/OPS/backlog feature is silently completed.

See [concrete finish evidence](EVIDENCE.md): 226 tests, one expected skip, clean
analysis, native builds and 35 country-mask render checks.

## External acceptance stays separate

- [ ] Actual phone cold/warm loading and label readability on a mobile network,
  with density/bytes/request counts and useful loading feedback observed.
- [ ] Actual GPS, notifications, permissions, minimized/screen-off continuation
  and touch remain physically accepted under the existing navigation plan.
- [ ] Verified saved hub/seller coordinates are returned by their API owner before
  claiming a hub-first map default. A null stop remains unavailable.

No USB phone was detected at activation. Desktop render/provider samples and APK
builds establish their own scope only; record that gap without inventing phone
measurements or weakening native/account authorization.
