# Rider screen inventory

Reviewed 2026-10-06. This is a counted design proposal, not a native route implementation.

## What counts as a page

A full view has a distinct task and designed composition. Reusable Stop Mode stages, filters, tabs, system prompts and error states are counted separately. A full-screen form step may share one implementation route with another step. Counts describe design coverage, not a mandated number of route files.

- **48 native full views:** 38 baseline, 3 selected feature views, 2 conditional and 5 optional.
- **8 external views/panels:** existing first-party application/recovery steps; these are not eight new native screens or necessarily eight web URLs.
- **20 app overlays**, **3 device-owned surfaces**, **15 shared states** and **8 Stop Mode stage variants**.
- **12 unselected future concepts:** 5 full views, 5 sheets and 2 components. If all five future full views were later chosen, the theoretical native full-view pool would be **53**. That is not current implementation scope.
- Current native operational screen implementation remains absent from the starter. The existing 180-card baseline is unchanged.

## Primary navigation

| Destination | Full view | Role |
|---|---|---|
| Tasks | [P05](PAGE_BLUEPRINTS.md#p05) | Stable top-level destination; never a duty or submit action |
| Trips | [P18](PAGE_BLUEPRINTS.md#p18) | Stable top-level destination; never a duty or submit action |
| Messages | [P21](PAGE_BLUEPRINTS.md#p21) | Stable top-level destination; never a duty or submit action |
| Profile | [P25](PAGE_BLUEPRINTS.md#p25) | Stable top-level destination; never a duty or submit action |

## Full native views

| ID | Page | Scope | Parent/context |
|---|---|---|---|
| [P01](PAGE_BLUEPRINTS.md#p01) | Sign in | baseline | start, P03 |
| [P02](PAGE_BLUEPRINTS.md#p02) | Application preparation | optional | P01, P32 |
| [P03](PAGE_BLUEPRINTS.md#p03) | Application and placement status | baseline | P01, E05 |
| [P04](PAGE_BLUEPRINTS.md#p04) | Restricted recovery overview | baseline | P03, P06 |
| [P05](PAGE_BLUEPRINTS.md#p05) | Home / Tasks | baseline | P01, P06, root |
| [P06](PAGE_BLUEPRINTS.md#p06) | Stop Mode | selected | P05, P19, P24 |
| [P07](PAGE_BLUEPRINTS.md#p07) | Waybill scanner | baseline | P06, P17 |
| [P08](PAGE_BLUEPRINTS.md#p08) | Parcel Finder | selected | P05, P06 |
| [P09](PAGE_BLUEPRINTS.md#p09) | Doorstep Guide | selected | P06, P10 |
| [P10](PAGE_BLUEPRINTS.md#p10) | Expanded saved-stop map | conditional | P06, P09 |
| [P11](PAGE_BLUEPRINTS.md#p11) | Delivery evidence | baseline | P06 |
| [P12](PAGE_BLUEPRINTS.md#p12) | Cash collection review | baseline | P11 |
| [P13](PAGE_BLUEPRINTS.md#p13) | Final handoff review | baseline | P11, P12 |
| [P14](PAGE_BLUEPRINTS.md#p14) | Recorded result receipt | baseline | P13, P06, P17 |
| [P15](PAGE_BLUEPRINTS.md#p15) | Failed-delivery form | baseline | P06, O10 |
| [P16](PAGE_BLUEPRINTS.md#p16) | Attempt and return timeline | baseline | P06, P15, P19 |
| [P17](PAGE_BLUEPRINTS.md#p17) | Restricted handover review | baseline | P04, P06 |
| [P18](PAGE_BLUEPRINTS.md#p18) | Trips | baseline | root, P14 |
| [P19](PAGE_BLUEPRINTS.md#p19) | Trip detail and journey | baseline | P18, P14, P23 |
| [P20](PAGE_BLUEPRINTS.md#p20) | Private proof viewer | baseline | P19, P14 |
| [P21](PAGE_BLUEPRINTS.md#p21) | Conversations | baseline | root, P06 |
| [P22](PAGE_BLUEPRINTS.md#p22) | Conversation thread | baseline | P21, P06 |
| [P23](PAGE_BLUEPRINTS.md#p23) | Activity inbox | baseline | P05, P25 |
| [P24](PAGE_BLUEPRINTS.md#p24) | Activity detail | baseline | P23 |
| [P25](PAGE_BLUEPRINTS.md#p25) | Profile | baseline | root |
| [P26](PAGE_BLUEPRINTS.md#p26) | Edit contact information | baseline | P25 |
| [P27](PAGE_BLUEPRINTS.md#p27) | Assignment and hub directory | baseline | P25, P06 |
| [P28](PAGE_BLUEPRINTS.md#p28) | Vehicle and credentials | baseline | P25 |
| [P29](PAGE_BLUEPRINTS.md#p29) | Settings | baseline | P25 |
| [P30](PAGE_BLUEPRINTS.md#p30) | Privacy and security | baseline | P29 |
| [P31](PAGE_BLUEPRINTS.md#p31) | Change password | baseline | P30 |
| [P32](PAGE_BLUEPRINTS.md#p32) | Help center | baseline | P29, P06, P03 |
| [P33](PAGE_BLUEPRINTS.md#p33) | Help guide | baseline | P32, P02 |
| [P34](PAGE_BLUEPRINTS.md#p34) | Contact help with parcel context | baseline | P32, P06, P04 |
| [P35](PAGE_BLUEPRINTS.md#p35) | Privacy notice | baseline | P29, P30 |
| [P36](PAGE_BLUEPRINTS.md#p36) | About Rider | baseline | P29 |
| [P37](PAGE_BLUEPRINTS.md#p37) | Cash responsibility overview | baseline | P25, P14, P19 |
| [P38](PAGE_BLUEPRINTS.md#p38) | Remittance instructions | baseline | P37 |
| [P39](PAGE_BLUEPRINTS.md#p39) | Remittance receipt | baseline | P37, P38, P24 |
| [P40](PAGE_BLUEPRINTS.md#p40) | Cash discrepancy detail | baseline | P37, P39 |
| [P41](PAGE_BLUEPRINTS.md#p41) | Confirmed earnings | baseline | P25, P37 |
| [P42](PAGE_BLUEPRINTS.md#p42) | Earning record detail | baseline | P41 |
| [P43](PAGE_BLUEPRINTS.md#p43) | Comfort preferences | optional | P29 |
| [P44](PAGE_BLUEPRINTS.md#p44) | Language preference | optional | P43 |
| [P45](PAGE_BLUEPRINTS.md#p45) | Appearance preference | optional | P43 |
| [P46](PAGE_BLUEPRINTS.md#p46) | How Rider works tour | optional | P32, P36 |
| [P47](PAGE_BLUEPRINTS.md#p47) | Account closure guidance | conditional | P30, P33 |
| [P48](PAGE_BLUEPRINTS.md#p48) | Device access and permissions | baseline | P29, P07 |

## External application and recovery

| ID | View/panel | Purpose |
|---|---|---|
| [E01](PAGE_BLUEPRINTS.md#e01) | Application: rider information | Enter real registration/contact and operating-area fields. |
| [E02](PAGE_BLUEPRINTS.md#e02) | Application: vehicle information | Provide the vehicle/license identifiers required by the current application. |
| [E03](PAGE_BLUEPRINTS.md#e03) | Application: documents and password | Review required private documents and credentials before submission. |
| [E04](PAGE_BLUEPRINTS.md#e04) | Email-code verification panel | Complete the existing registration or recovery email challenge. |
| [E05](PAGE_BLUEPRINTS.md#e05) | Application correction and resubmission | Respond to reviewer feedback in the current web flow. |
| [E06](PAGE_BLUEPRINTS.md#e06) | Password recovery request | Start the supported recovery channel for the registered account. |
| [E07](PAGE_BLUEPRINTS.md#e07) | Recovery: new password | Set the password after the real verified challenge or reset link. |
| [E08](PAGE_BLUEPRINTS.md#e08) | Email verification outcome | Read the actual email verification result and return to refresh the account. |

## App overlays

| ID | Overlay | Owning context | Scope |
|---|---|---|---|
| [O01](PAGE_BLUEPRINTS.md#o01) | Go off duty | P05 | baseline |
| [O02](PAGE_BLUEPRINTS.md#o02) | Queue/history filters | P05 | baseline |
| [O03](PAGE_BLUEPRINTS.md#o03) | Pickup claim review | P06 | baseline |
| [O04](PAGE_BLUEPRINTS.md#o04) | Scan match review | P07 | baseline |
| [O05](PAGE_BLUEPRINTS.md#o05) | Choose parcel compartment | P08 | selected |
| [O06](PAGE_BLUEPRINTS.md#o06) | Proof source choice | P11 | baseline |
| [O07](PAGE_BLUEPRINTS.md#o07) | Replace or remove proof | P11 | baseline |
| [O08](PAGE_BLUEPRINTS.md#o08) | Discard unsaved draft | caller | baseline |
| [O09](PAGE_BLUEPRINTS.md#o09) | Sign out | P29 | baseline |
| [O10](PAGE_BLUEPRINTS.md#o10) | Cash problem guidance | P12 | baseline |
| [O11](PAGE_BLUEPRINTS.md#o11) | Read-only code lookup | P07 | conditional |
| [O12](PAGE_BLUEPRINTS.md#o12) | Call a permitted contact | P06 | baseline |
| [O13](PAGE_BLUEPRINTS.md#o13) | Open navigation | P10 | baseline |
| [O14](PAGE_BLUEPRINTS.md#o14) | Activity item actions | P23 | baseline |
| [O15](PAGE_BLUEPRINTS.md#o15) | Read-status explanation | P22 | baseline |
| [O16](PAGE_BLUEPRINTS.md#o16) | Cash and earnings meaning | P37 | baseline |
| [O17](PAGE_BLUEPRINTS.md#o17) | Date-range selection | P18 | baseline |
| [O18](PAGE_BLUEPRINTS.md#o18) | Email verification guidance | P30 | baseline |
| [O19](PAGE_BLUEPRINTS.md#o19) | Choose help parcel context | P34 | baseline |
| [O20](PAGE_BLUEPRINTS.md#o20) | Why this action is unavailable | caller | baseline |

## Device-owned surfaces

| ID | Name | Visible behavior |
|---|---|---|
| Z01 | Device camera permission | System-owned permission request after a contextual explanation; the app cannot recolor or fake its approval. |
| Z02 | Device camera / media picker | System-owned capture/selection surface; preserve the app's parcel context and recover cancellation/interruption. |
| Z03 | Device navigation-app chooser | Installed app choice/launch result; native look is device-owned and not an app design page. |

## Shared states

| ID | Name | Visible behavior |
|---|---|---|
| S01 | Loading | Show a finite progress description or skeleton for the requested region; retain safe context without sample work. |
| S02 | Returned empty / no matches | Use a small quiet parcel motif and an actual next step; distinguish empty scope from a filter with no results. |
| S03 | Read failed | Keep page identity and Retry; do not replace unknown counts with zero or erase authorized drafts. |
| S04 | Refreshing / stale | Show last successful refresh when known; selection stays bound to the parcel and mutations recheck fresh permission. |
| S05 | Connection unavailable | Keep allowed text/drafts, show recovery and honest unavailable submission; do not promise offline custody. |
| S06 | Submitting | Name the action in progress, block repeated taps, keep the parcel visible and explain permitted cancellation. |
| S07 | Validation rejected | Inline field errors plus announced summary, focus/scroll to first issue, preserve only safe permitted inputs. |
| S08 | Denied / stale assignment | Show the server reason safely and refresh/return; never locally replay an action on another parcel. |
| S09 | Result unconfirmed | Show Checking whether this was recorded and an accepted reconciliation path before a same-intent retry. |
| S10 | Confirmed result | Use specific recorded outcome, time/reference when supplied and useful next step; no inferred buyer completion/payout. |
| S11 | Capability or data unavailable | Explain what is unavailable; hide unsupported actions or give a focusable reason; never invent values or no-op preferences. |
| S12 | Permission unavailable | Differentiate denied/restricted/permanently denied using actual device state; offer supported settings or permitted fallback. |
| S13 | Session ended / account changed | Return to sign-in or holding and clear previous-account private state; sign-out does not remove custody responsibilities. |
| S14 | Read-only / completed phase | Keep authorized history readable; disable sending/editing with a reason; an old record cannot gain live authority. |
| S15 | Compatibility / unknown status | Use safe holding guidance, actual supported help/update links and fresh check; no guessing a new status or endpoint. |

## Stop Mode variants

| ID | Stage | Authorized stop | Primary interaction | Truth |
|---|---|---|---|---|
| V01 | Available pickup | Seller preview | Claim pickup through O03 | Preview, not custody; claim eligibility is fresh. |
| V02 | Claimed pickup | Seller | Scan and review actual collection | Claim created responsibility; seller handoff is still required. |
| V03 | Collected pickup | Assigned origin hub | Directions / await hub intake | Hub records receipt; rider cannot self-confirm origin intake. |
| V04 | Assigned final-mile | Destination hub | Scan and review departure | Hub assignment precedes physical departure; no self-claim of other parcels. |
| V05 | Out for delivery | Saved buyer destination | Open evidence flow P11 | Exact COD, doorstep notes and genuine evidence; no buyer completion. |
| V06 | Delivery recorded | Recorded recipient handoff | View receipt or next work | Buyer confirmation and cash remittance remain separate. |
| V07 | Failed delivery / return | Destination hub | Open return instructions / await receipt | Held parcel remains visible until hub-owned return acceptance. |
| V08 | Restricted recovery | Authorized receiving hub | Open permitted recovery P17 | Narrow capability only; this is not ordinary portal access. |

## Unselected future concepts

| ID | Concept | Type |
|---|---|---|
| [F01](PAGE_BLUEPRINTS.md#f01) | Shift readiness | sheet |
| [F02](PAGE_BLUEPRINTS.md#f02) | Shift closeout | full_view |
| [F03](PAGE_BLUEPRINTS.md#f03) | Wrong-pin or entrance report | sheet |
| [F04](PAGE_BLUEPRINTS.md#f04) | Arrival estimate and route plan | full_view |
| [F05](PAGE_BLUEPRINTS.md#f05) | Batch load checklist | full_view |
| [F06](PAGE_BLUEPRINTS.md#f06) | Same-stop parcel group | component |
| [F07](PAGE_BLUEPRINTS.md#f07) | Queue changed review | sheet |
| [F08](PAGE_BLUEPRINTS.md#f08) | Recipient PIN verification | sheet |
| [F09](PAGE_BLUEPRINTS.md#f09) | Shift statement preview | full_view |
| [F10](PAGE_BLUEPRINTS.md#f10) | Editable quick replies | component |
| [F11](PAGE_BLUEPRINTS.md#f11) | Incident report | sheet |
| [F12](PAGE_BLUEPRINTS.md#f12) | Consented location sharing | full_view |

## Coverage of every major work area

| Area | Designed surfaces | Why included |
|---|---|---|
| M01 | P01, P06, P09, P11, P37 | Visible values/actions depend on agreed resources; no field/API is inferred from a drawing. |
| M02 | P05, P18, P21, P25, O08 | Shared shell, fields, safe areas, focus and recoverable modal patterns. |
| M03 | P01, P02, P03, E01, E02, E03, E04, E05, E06, E07, E08, O09 | Entry, holding, existing web onboarding/recovery and logout. |
| M04 | P05, P06, P08, O02, O20 | Own work overview, task detail, selection and chosen organization extension. |
| M05 | P05, O01, P03 | Duty and working eligibility without hiding existing custody. |
| M06 | P06, P07, P08, O03, O04 | Claimed seller pickup to origin-hub receipt, including real scan review. |
| M07 | P06, P07, P11, P12, P13, P14, O06, O07, O10 | Assigned hub departure, recipient/evidence/cash review and confirmed outcome. |
| M08 | P04, P06, P15, P16, P17 | Failure, return responsibility and limited recovery. |
| M09 | P06, P09, P10, P27, O12, O13 | Phase-correct address, selected instruction extension, map and contact fallback. |
| M10 | P21, P22, O15 | Conversation/list, context, composer, read and stale-phase behavior. |
| M11 | P14, P18, P19, P20, O17 | Recorded results, history, timeline, scoped proof and filters. |
| M12 | P23, P24, O14 | Durable notice list/details and own read actions. |
| M13 | P25, P26, P27, P28 | Own identity, permitted contact edits and managed placement/vehicle facts. |
| M14 | P29, P30, P31, P32, P33, P34, P35, P36, P43, P44, P45, P46, P47, P48 | Settings, security/help/notice/about, device access and explicitly optional pages. |
| M15 | P12, P37, P38, P39, P40, P41, P42, O16 | Exact cash, remittance, discrepancy, reconciliation and confirmed earnings. |
| M16 | O08, S01, S02, S03, S04, S05, S06, S07, S08, S09, S10, S11, S12, S13, S14, S15, Z01, Z02, Z03 | Every page inherits error/access/lifecycle, keyboard, accessibility and device checks. |

## Coverage of the earlier 40 ideas

Every earlier idea resolves to a specified page, state or explicitly future concept. This mapping does not select all those ideas for implementation.

| Research idea | Designed surface IDs |
|---|---|
| 01 | P06 |
| 02 | P05 |
| 03 | F01 |
| 04 | P05, P06, S04 |
| 05 | F02 |
| 06 | P10, F04 |
| 07 | P09 |
| 08 | F03 |
| 09 | O13, P43 |
| 10 | F04, F12 |
| 11 | P08, O05 |
| 12 | F05 |
| 13 | F06 |
| 14 | F07 |
| 15 | P06, O03 |
| 16 | P07, O04 |
| 17 | P14, V03 |
| 18 | P11, P12, P13 |
| 19 | P12 |
| 20 | P11, F08 |
| 21 | P14 |
| 22 | P15 |
| 23 | P06, V07 |
| 24 | P16 |
| 25 | P18, P19 |
| 26 | P37 |
| 27 | P41, P42 |
| 28 | F09 |
| 29 | F10 |
| 30 | P22 |
| 31 | P23, P24 |
| 32 | P01, E06, E07 |
| 33 | P02, E01, E02, E03 |
| 34 | E03, E05 |
| 35 | P03 |
| 36 | P46 |
| 37 | P27 |
| 38 | P43, P44, P45 |
| 39 | P32, P34, F11 |
| 40 | S01, S03, S04, S05, S06, S09 |

The canonical design data is [screens.json](screens.json). Validate and regenerate with the design rendering tool. Navigation IDs are planning references, not backend endpoints.
