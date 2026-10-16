# Deployment and activation gate

**October 16 selected state: HDB-05 duty/claim accepted.**
[Dated native and website evidence](../home-dashboard-branch-plan/HDB-05-EVIDENCE.md)
records running revision/migrations, fresh Home/queues/owned detail, controlled
duty/claim/recovery and the owning website's 20/20 confirmation. Final review
enables only the approved local Azure duty/claim build profile. Other operation
batches, simultaneous two-rider and physical Android acceptance remain separate.
The original October 9 handoff did not establish any of these later results.

## Evidence required before live operational testing

1. Obtain the operator's actual Azure deployed revision and migration/config
   evidence. Compare it with the reviewed backend source and any later fixes.
   `operations_api_version: 1` alone does not identify the exact deployed commit.
2. Verify the additive `2026_10_09_010000_create_rider_commands_table` migration
   and the required existing Settings/checkpoint/COD/source migrations. Discovery
   stays unavailable if these sources are missing. Preserve private proof storage,
   retained command records and backups; no destructive rollback or reset.
3. Confirm normal first-party HTTPS `/api/v1` JSON routing, privacy/cache headers,
   proof/body limits and existing notification workers/scheduler. The operator
   owns rollout through the backend's established deploy/verify procedure.
4. Sign in privately again to obtain the new narrow operational abilities.
   Check account discovery and `GET rider/home`: version 1, actual capabilities,
   placement, eligibility, capacity and limits. Missing placement is a real
   denial, not proof of a broken endpoint or permission to invent a hub.
5. Confirm old/missing abilities and wrong/restricted accounts reject access;
   holding accounts keep their existing account screens. Keep account/Settings
   regression evidence separate from operational readiness.
6. Use authorized isolated test parcels, recipients and cash sources for later
   writes. Record native API and owning website/hub/buyer observations, without
   retaining credentials, tokens, private proof or real identities in public docs.

An unauthenticated 401, source tests, a reachable hostname or a fixture response
cannot prove this gate. Physical Android scanner/permission/proof tests are also
separate from a Linux layout frame or a successful APK build.

## Evidence record for the selected implementation

| Field | Current value |
|---|---|
| Reviewed source | Initial `1d785aa` in [source review](SOURCE_REVIEW.md); HDB-05 reviewed clean `4b9f610` |
| Deployed source / migrations | Owner verified `c262473`, 75 migrations applied, none pending, required command constraints/routes present |
| Fresh operational bearer / Home | Approved version-1 native sign-in, Home capabilities/limits, all three queues and owned detail passed |
| Native client / cross-role checks | Controlled duty/claim/replay/recovery passed; independent website post-check 20/20 |
| Actual Android checks | Not performed |
| Activation / later follow-up | Accepted local duty/claim profile enabled; broader parcel/proof/finance/device gates remain with their selected batches |

Report a specific endpoint, response code/request ID, schema mismatch or missing
migration/configuration rather than declaring the whole backend unavailable.
Do not put SSH aliases, machine paths, credentials or deployment scripts into
this mobile plan. The backend's historical public-proof audit/removal procedure
remains an operator-reviewed release prerequisite; this document authorizes no
historical deletion or migration.
