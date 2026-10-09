# Rider page blueprints

The modern mobile visual target is independent of portal styling; shared colors, role-specific rounded geometry, grouped surfaces and neutral reference language follow [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md). This documentation target does not change runtime styling.

These are frontend specifications for all counted views. Read [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md) and [RESEARCH_AND_RATIONALE.md](RESEARCH_AND_RATIONALE.md) for shared tokens and limits of the theories. Every data page uses the applicable shared states in [SCREEN_INVENTORY.md](SCREEN_INVENTORY.md#shared-states); the specific recovery rule below adds its own context.

Entry/next IDs describe intended navigation, not actual deployed routes. A temporary focus workflow restores its parent, and Back never transfers a draft or command to another parcel.

<a id="p01"></a>
## P01 — Sign in

**Purpose:** Enter the approved courier account and understand access results.

**Scope / owner:** baseline / M03. Accepted sign-in and own-account contract; no browser-to-native session assumption.

**Enter / next:** start, P03 → P05, P03, E06, P02. No operational navigation before fresh authorized entry. Back/recovery/application links retain their real purpose.

**Top region:** Small BagooPH identity, Sign in heading, short purpose.

**Content order:** Persistent email label and autofill → Password with accessible show/hide control → Remember-email meaning separate from session persistence.

**Primary control and placement:** Sign in: full-width after the fields; stays above the keyboard when needed.

**Secondary controls:** Forgot password under password; Apply as a rider below the main action.

**Color, borders and grouping — why:** One red submit button makes the next action distinct; softly filled labelled fields make editing recognizable. Recovery links use dark accent text rather than rival filled buttons.

**Theory and thumb reasoning:** Jakob, Hick and error prevention: familiar labelled fields, staged choice and field recovery. Large lower actions stay above device/navigation/keyboard insets; the lowest screen edge is not assumed universally comfortable.

**Responsive behavior:** At 320–599 units use one column; at 600+ center the form at 560 units maximum. At 200% text stack label/action pairs and let the page scroll above the keyboard.

**Recovery and honesty:** Bad credentials remain beside the correct field; expired session explains re-entry; unknown or wrong-role access does not open Tasks.

<a id="p02"></a>
## P02 — Application preparation

**Purpose:** Prepare the rider to complete the existing application without surprise uploads.

**Scope / owner:** optional / M03. First-party onboarding remains the recommended initial flow; this preparation view is an optional design addition.

**Enter / next:** P01, P32 → E01, P01. No operational navigation before fresh authorized entry. Back/recovery/application links retain their real purpose.

**Top region:** Apply as a rider, Back and concise eligibility explanation.

**Content order:** Required identity and vehicle documents → Accepted format/size from the current policy → Three application stages and what happens after submission.

**Primary control and placement:** Continue application: full-width lower action opens approved first-party entry.

**Secondary controls:** Already applied: Sign in; document help opens P33.

**Color, borders and grouping — why:** An unboxed checklist reads as guidance, not completed verification; the red continuation identifies one path. Status claims are absent until a real submission is read.

**Theory and thumb reasoning:** Grouping, progressive disclosure and recognition: readable instructions before optional detail. Large lower actions stay above device/navigation/keyboard insets; the lowest screen edge is not assumed universally comfortable.

**Responsive behavior:** Reading column is at most 680 units and wraps at 320. Wide windows can show a contents rail; keyboard focus and large text preserve reading order.

**Recovery and honesty:** Missing requirements show unavailable guidance instead of fabricated limits; leaving keeps no document files in this page.

<a id="p03"></a>
## P03 — Application and placement status

**Purpose:** Explain review, correction, placement or access restrictions accurately.

**Scope / owner:** baseline / M03. Fresh approval/activity/placement capabilities; native resubmission is not enabled by this design.

**Enter / next:** P01, E05 → P05, E05, P04, O09. No ordinary work tabs while access is restricted. Show only actual allowed refresh, correction, recovery, help and sign-out paths.

**Top region:** Account name, exact status, last successful refresh.

**Content order:** Pending: submitted details and neutral waiting explanation → Rejected: supplied feedback and correction link → Approved but unplaced: assignment pending and authorized contact → Inactive or suspended: permitted guidance and any narrow recovery link.

**Primary control and placement:** Contextual action: Refresh status, Correct application or Open recovery, depending on returned permission.

**Secondary controls:** Sign out stays visible; help is below the status explanation.

**Color, borders and grouping — why:** Sand is for waiting/action-needed explanation; approved identity alone does not get a green Ready for work badge. Status text carries meaning independently of color.

**Theory and thumb reasoning:** Feedback and recognition: visible exact status and responsible actor avoid guessing what is pending. Large lower actions stay above device/navigation/keyboard insets; the lowest screen edge is not assumed universally comfortable.

**Responsive behavior:** Keep one readable status column on phones; center to 640 units on wider windows. Long feedback wraps; receiving instructions remain above any action.

**Recovery and honesty:** Unknown review state is unresolved, not approved; unavailable status differs from a rejected application; do not promise a review turnaround without supplied evidence.

<a id="p04"></a>
## P04 — Restricted recovery overview

**Purpose:** Show only explicitly authorized held-work recovery.

**Scope / owner:** baseline / M08. Accepted narrow recovery contract and authorized receiving data.

**Enter / next:** P03, P06 → P17, P34. No ordinary work tabs while access is restricted. Show only actual allowed refresh, correction, recovery, help and sign-out paths.

**Top region:** Restriction explanation and named receiving hub when authorized.

**Content order:** Allowed held parcels and cash responsibilities → Receiving instruction and responsible actor → Status of outstanding recovery.

**Primary control and placement:** Open authorized handover: lower action only when returned as available.

**Secondary controls:** Contact the approved receiving team; sign out does not surrender custody.

**Color, borders and grouping — why:** A quiet sand panel explains the restriction; a neutral list limits visual claims to returned duties. No ordinary task navigation appears.

**Theory and thumb reasoning:** Recognition, grouping and progressive disclosure: key facts and one relevant action precede secondary records. Large lower actions stay above device/navigation/keyboard insets; the lowest screen edge is not assumed universally comfortable.

**Responsive behavior:** Compact uses labelled definition rows and readable wrapping. Wide can pair a related panel with the main column, never stretching a form or duplicating the action.

**Recovery and honesty:** Missing recovery capability shows contact guidance; suspended status never becomes a normal dashboard through a cached task.

<a id="p05"></a>
## P05 — Home / Tasks

**Purpose:** Find the next responsibility before statistics or decoration.

**Scope / owner:** baseline / M04. Scoped queue/capacity contract; selection is presentation and never optimization.

**Enter / next:** P01, P06, root → P06, P08, P23, O01, O02. Persistent Tasks / Trips / Messages / Profile navigation. Actions are not tabs. Native medium/wide uses a rail when geometry permits.

**Top region:** Identity, assigned hub, duty switch and activity entry; heading Your tasks.

**Content order:** Available pickups / Active pickups / Delivery filters with returned counts → Prominent selected or continuing task: stage, stop, full parcel reference, exact cash when relevant → Remaining queue in supplied order → Small truthful daily activity only after operational work.

**Primary control and placement:** Open Stop Mode on the prominent task; Claim pickup remains inside the available-task review.

**Secondary controls:** Search within this queue; filters open O02; duty change uses O01.

**Color, borders and grouping — why:** One raised white current-task card gives hierarchy without outlining every row. Rose selection and dark text mark the active filter; secondary rows use spacing and subtle dividers.

**Theory and thumb reasoning:** Grouping, Hick and recognition: stable categories and labelled rows reduce searching and repeated memory. Large lower actions stay above device/navigation/keyboard insets; the lowest screen edge is not assumed universally comfortable.

**Responsive behavior:** One list column on compact widths. At 960+ use a 300-unit list with detail only when the remaining detail pane is at least 420 units; preserve selection through reflow.

**Recovery and honesty:** Off duty retains active work; missing assignment has placement guidance; empty queue differs from failed load; no map or fake totals in empty state.

<a id="p06"></a>
## P06 — Stop Mode

**Purpose:** Finish the current authorized stop from one focused working view.

**Scope / owner:** selected / M04. Existing task/command acceptance, selected tag/instruction dependencies and optional map decision.

**Enter / next:** P05, P19, P24 → P07, P08, P09, P10, P11, P15, P14, P17, P22. Parent tab stays selected; compact read/detail views keep the tab bar. Back returns to the actual origin with selection/scroll preserved.

**Top region:** Back, current phase/stage, full tracking reference and Help.

**Content order:** Destination name and full address → Doorstep Guide excerpt with Open instructions → Compact saved-stop map if supported → Parcel Finder position when set → Exact COD or explicit prepaid/unavailable cash state → Short next-step instruction.

**Primary control and placement:** One stage-specific primary action in a sticky lower shelf above the navigation bar.

**Secondary controls:** Directions, Call and Message are neutral labelled controls beside the destination; Finder and guide links sit with their information.

**Color, borders and grouping — why:** The primary shelf is red only for the permitted next action. Map and address form one group; instructions are borderless unless a warning needs a sand inset; selection never means custody.

**Theory and thumb reasoning:** Hick, grouping, distinctiveness and thumb reach: one permitted action with the parcel, address and evidence context. Large lower actions stay above device/navigation/keyboard insets; the lowest screen edge is not assumed universally comfortable.

**Responsive behavior:** Compact stack keeps address and action before optional map detail. At 960+ put map beside the task with 420+ units for task content; collapse back to one stack at large text.

**Recovery and honesty:** Eight stage variants are catalogued separately. Missing pin keeps address usable; stale permission removes the mutation; a lost response shows checking rather than success.

<a id="p07"></a>
## P07 — Waybill scanner

**Purpose:** Read genuine parcel input and review the match before custody changes.

**Scope / owner:** baseline / M06. Camera adapter, physical-phone verification and accepted waybill evidence.

**Enter / next:** P06, P17 → O04, O11, Z01, P06. Temporary full-screen workflow covers the tab bar. Back/Close and parcel context stay visible; exiting restores the originating tab and safe draft state.

**Top region:** Close or Back, expected parcel, accessible torch control.

**Content order:** Camera view with a bounded scan guide → Instructions outside the camera image → Expected full tracking reference → Read-result feedback and recovery.

**Primary control and placement:** Review match after a real read; never auto-confirm a custody transition.

**Secondary controls:** Torch is a 48-unit target; read-only code lookup uses O11 only if useful.

**Color, borders and grouping — why:** Camera content has no decorative card; white/opaque control backplates preserve contrast. Match feedback includes text and icon, not only green.

**Theory and thumb reasoning:** Fitts and feedback: large controls outside the viewfinder and explicit actual-code review. Large lower actions stay above device/navigation/keyboard insets; the lowest screen edge is not assumed universally comfortable.

**Responsive behavior:** Fit the camera to available width/height; landscape keeps opaque controls beside it without covering the scan guide. Large text can reduce camera area, never the labels.

**Recovery and honesty:** Denied camera offers device settings and permitted lookup; wrong, duplicate or unreadable code cannot produce a match; one pending read/review at a time.

<a id="p08"></a>
## P08 — Parcel Finder

**Purpose:** Locate the rider's parcel in a compartment or bag.

**Scope / owner:** selected / M04. Selected tag model, session-only versus private persistence and cleanup decision; current multi-pickup capacity only.

**Enter / next:** P05, P06 → O05, P06, P07. Parent tab stays selected; compact read/detail views keep the tab bar. Back returns to the actual origin with selection/scroll preserved.

**Top region:** Parcel Finder, current scope and clear organization-only explanation.

**Content order:** List of owned parcels with full reference and optional suffix emphasis → Small motorcycle/bag diagram with labelled slots → Selected parcel position and edit/clear actions.

**Primary control and placement:** Set parcel location: opens O05 for the selected owned parcel.

**Secondary controls:** Find by tracking reference; return to Stop Mode; scan identity through P07.

**Color, borders and grouping — why:** Rose highlights one selected slot; other slots have filled surfaces, visible selection indicators and text labels. A diagram is a personal memory aid, so it has no verified/custody badge.

**Theory and thumb reasoning:** Recognition, grouping and thumb reach: a labelled spatial aid supplements full parcel identity. Large lower actions stay above device/navigation/keyboard insets; the lowest screen edge is not assumed universally comfortable.

**Responsive behavior:** Diagram and selected parcel stack on phones; a wide window places parcel list beside the diagram. Slots retain 48-unit targets and text labels; no drag-only assignment.

**Recovery and honesty:** Unset location stays explicit; refresh preserves authorized local tags; account change clears scoped private state; final-mile multi-parcel load is not implied.

<a id="p09"></a>
## P09 — Doorstep Guide

**Purpose:** Understand the correct collection point or entrance before travel and handoff.

**Scope / owner:** selected / M09. Authorized phase-specific instruction data and update ownership; text-first selection excludes an automatic photo or pin-report service.

**Enter / next:** P06, P10 → P10, P06, O12. Parent tab stays selected; compact read/detail views keep the tab bar. Back returns to the actual origin with selection/scroll preserved.

**Top region:** Stop name, phase and the original destination.

**Content order:** Authorized landmark and entrance → Floor/unit or collection-counter instructions → Access notes as plain text → Destination and contact fallback.

**Primary control and placement:** Directions to the saved destination: lower neutral action; guide reading itself is not a mutation.

**Secondary controls:** Copy address; call verified phase contact; return to Stop Mode.

**Color, borders and grouping — why:** Borderless text sections avoid treating each sentence as a button. Only a materially important access warning uses a tinted inset; the destination remains dark and prominent.

**Theory and thumb reasoning:** Grouping, progressive disclosure and recognition: readable instructions before optional detail. Large lower actions stay above device/navigation/keyboard insets; the lowest screen edge is not assumed universally comfortable.

**Responsive behavior:** Reading column is at most 680 units and wraps at 320. Wide windows can show a contents rail; keyboard focus and large text preserve reading order.

**Recovery and honesty:** No notes says No extra instructions provided; unknown fields do not become guessed landmarks; clarification cannot silently redirect a parcel.

<a id="p10"></a>
## P10 — Expanded saved-stop map

**Purpose:** Explore the authorized saved stop without losing the address or task.

**Scope / owner:** conditional / M09. Embedded-map M09.07 decision and provider policy; expanded layout is conditional until the renderer/data are accepted.

**Enter / next:** P06, P09 → P06, P09, O13. Parent tab stays selected; compact read/detail views keep the tab bar. Back returns to the actual origin with selection/scroll preserved.

**Top region:** Back, Saved stop label and parcel context.

**Content order:** Street map with one authorized destination pin → Opaque stop/address summary → Labelled zoom and Show stop controls → Visible attribution and load feedback.

**Primary control and placement:** Directions: neutral control in the lower address shelf; custody action remains in Stop Mode.

**Secondary controls:** Show stop, zoom, Copy address and Open instructions.

**Color, borders and grouping — why:** One bounded 16-unit map frame contains visual complexity. Opaque controls protect contrast; a stationary pin means a saved destination, never live rider location.

**Theory and thumb reasoning:** Grouping, Fitts and error prevention: opaque controls, an equivalent stop list/address and explicit directions. Large lower actions stay above device/navigation/keyboard insets; the lowest screen edge is not assumed universally comfortable.

**Responsive behavior:** Map uses remaining bounded space without swallowing the address. Compact controls occupy an opaque lower/side group; low-height landscape and large text favor the textual stop view.

**Recovery and honesty:** Missing coordinates use the address layout; tile error preserves text and manual retry; no predicted route line, ETA, geofence enforcement or offline bulk tiles.

<a id="p11"></a>
## P11 — Delivery evidence

**Purpose:** Review recipient evidence and a genuine proof image.

**Scope / owner:** baseline / M07. Accepted evidence fields/limits, private media handling and real-device lifecycle verification.

**Enter / next:** P06 → Z02, O06, O07, P12, P13, O08. Temporary full-screen workflow covers the tab bar. Back/Close and parcel context stay visible; exiting restores the originating tab and safe draft state.

**Top region:** Parcel reference, step label and Back.

**Content order:** Returned recipient/relationship requirements → Photo source action and proof thumbnail with replace/remove → Optional note with limit and inline errors → Brief evidence guidance.

**Primary control and placement:** Continue: full-width lower action after required evidence is ready.

**Secondary controls:** Replace/remove photo near the thumbnail; cancel via discard-draft O08.

**Color, borders and grouping — why:** Fields have persistent labels and soft fills; photo is grouped in one white surface. One red continuation avoids competing Capture, Retake and Submit colors.

**Theory and thumb reasoning:** Jakob, Hick and error prevention: familiar labelled fields, staged choice and field recovery. Large lower actions stay above device/navigation/keyboard insets; the lowest screen edge is not assumed universally comfortable.

**Responsive behavior:** At 320–599 units use one column; at 600+ center the form at 560 units maximum. At 200% text stack label/action pairs and let the page scroll above the keyboard.

**Recovery and honesty:** Camera/picker interruption recovers only the authorized draft; rejected upload keeps safe input; photo selection does not record delivery.

<a id="p12"></a>
## P12 — Cash collection review

**Purpose:** Make exact cash due understandable and check change before handoff.

**Scope / owner:** baseline / M07. Accepted exact-cash acknowledgement; helper does not replace the server amount or create remittance.

**Enter / next:** P11 → P13, O10, P15. Temporary full-screen workflow covers the tab bar. Back/Close and parcel context stay visible; exiting restores the originating tab and safe draft state.

**Top region:** Parcel reference and Cash at delivery.

**Content order:** Exact server amount due → Payment method or clear no-COD state → Optional cash-tendered helper and read-only correct change → Acknowledgement required by the accepted outcome.

**Primary control and placement:** Continue to review: lower red action only when the required cash evidence is valid.

**Secondary controls:** Cash problem opens O10; Back preserves permitted entered evidence.

**Color, borders and grouping — why:** Amount due is dark and large; the card is not a colored earnings tile. Tender/change rows use grouping and a divider to keep calculation separate from recorded cash.

**Theory and thumb reasoning:** Recognition and error prevention: clear amount meanings and labelled review precede any accepted financial action. Large lower actions stay above device/navigation/keyboard insets; the lowest screen edge is not assumed universally comfortable.

**Responsive behavior:** Currency and labels stay together on phones; two columns are allowed only for independent groups on wide windows. At 200% text put amount underneath its label.

**Recovery and honesty:** Missing or invalid COD is unavailable, not zero; insufficient tender offers the allowed issue path; prepaid work skips unnecessary cash entry.

<a id="p13"></a>
## P13 — Final handoff review

**Purpose:** Catch wrong parcel, evidence or cash before recording the outcome.

**Scope / owner:** baseline / M07. Accepted outcome/idempotency contract; this records DELIVERED rather than buyer completion.

**Enter / next:** P11, P12 → P14, P11, P12, P15, O08. Temporary full-screen workflow covers the tab bar. Back/Close and parcel context stay visible; exiting restores the originating tab and safe draft state.

**Top region:** Review handoff and full parcel identity.

**Content order:** Saved recipient and destination → Authorized proof preview → Exact collection summary where required → Editable section links and clear outcome wording.

**Primary control and placement:** Record delivery: one lower red submit; changes to Recording while pending.

**Secondary controls:** Edit evidence or cash next to that section; Cancel does not cancel assignment.

**Color, borders and grouping — why:** One review surface keeps related facts together; dark labelled values support recognition. The only saturated action is the actual record submission.

**Theory and thumb reasoning:** Jakob, Hick and error prevention: familiar labelled fields, staged choice and field recovery. Large lower actions stay above device/navigation/keyboard insets; the lowest screen edge is not assumed universally comfortable.

**Responsive behavior:** At 320–599 units use one column; at 600+ center the form at 560 units maximum. At 200% text stack label/action pairs and let the page scroll above the keyboard.

**Recovery and honesty:** Double tap is blocked; validation returns to the affected step with safe drafts; uncertain response is S09 and must reconcile before retry.

<a id="p14"></a>
## P14 — Recorded result receipt

**Purpose:** See what the server actually recorded and what responsibility remains.

**Scope / owner:** baseline / M11. Recorded event and authorized proof/history data; receipt cannot grant a new transition.

**Enter / next:** P13, P06, P17 → P05, P19, P06, P37. Parent tab stays selected; compact read/detail views keep the tab bar. Back returns to the actual origin with selection/scroll preserved.

**Top region:** Outcome title, parcel and recorded time.

**Content order:** Accepted result and event reference → Permitted evidence summary → Receiving hub for intake/return results → Buyer confirmation and cash duties shown separately.

**Primary control and placement:** Next task or View record: neutral lower action; no second record button.

**Secondary controls:** Open related timeline; show remaining cash responsibility only when available.

**Color, borders and grouping — why:** A small mint result inset with icon/text acknowledges confirmed evidence. The rest is white and readable; no confetti, countdown or implied payout.

**Theory and thumb reasoning:** Feedback and distinctiveness: the confirmed outcome is specific and the next action is calm. Large lower actions stay above device/navigation/keyboard insets; the lowest screen edge is not assumed universally comfortable.

**Responsive behavior:** One centered receipt column on compact and wide windows, 680-unit maximum. Extra detail can expand below, while the recorded status stays near the heading.

**Recovery and honesty:** Only server-confirmed result opens this receipt; origin intake, return receipt and delivery are named variants rather than separate new routes.

<a id="p15"></a>
## P15 — Failed-delivery form

**Purpose:** Record a permitted reason and understand the next responsibility.

**Scope / owner:** baseline / M08. Accepted exception reasons/evidence, attempt record and hub-return contract.

**Enter / next:** P06, O10 → P06, P16, O08. Temporary full-screen workflow covers the tab bar. Back/Close and parcel context stay visible; exiting restores the originating tab and safe draft state.

**Top region:** Could not deliver, parcel and current destination.

**Content order:** Permitted reason list with plain labels → Required note/evidence by reason → Preview of returned next instruction → Explicit reminder that failure does not end custody.

**Primary control and placement:** Record failed attempt: lower red action after required fields.

**Secondary controls:** Back/Cancel preserves or discards through O08; approved help stays nearby.

**Color, borders and grouping — why:** Reason fields and evidence boundaries are visible; sand communicates the return implication without using alarm red for every item.

**Theory and thumb reasoning:** Jakob, Hick and error prevention: familiar labelled fields, staged choice and field recovery. Large lower actions stay above device/navigation/keyboard insets; the lowest screen edge is not assumed universally comfortable.

**Responsive behavior:** At 320–599 units use one column; at 600+ center the form at 560 units maximum. At 200% text stack label/action pairs and let the page scroll above the keyboard.

**Recovery and honesty:** Unknown failure code is unsupported; denied/stale attempts refresh; recorded attempt count is server-owned; no rider-selected retry date.

<a id="p16"></a>
## P16 — Attempt and return timeline

**Purpose:** Understand attempts, receipt and the hub's next decision.

**Scope / owner:** baseline / M08. Recorded exception history, fresh instruction and private evidence permissions.

**Enter / next:** P06, P15, P19 → P06, P14, P34. Parent tab stays selected; compact read/detail views keep the tab bar. Back returns to the actual origin with selection/scroll preserved.

**Top region:** Parcel reference and Recorded attempts.

**Content order:** Time-ordered attempts with supplied reason/evidence → Hub return pending/received events → Approved retry decision or reverse-logistics instruction → Responsible actor for the current wait.

**Primary control and placement:** Open current responsibility: neutral lower link to Stop Mode.

**Secondary controls:** Open authorized evidence or help; filters do not erase attempts.

**Color, borders and grouping — why:** Timeline uses a quiet line and labelled status dots; the current instruction alone receives sand or rose emphasis. Past records remain neutral.

**Theory and thumb reasoning:** Grouping and recognition: connected actual events communicate sequence without inventing progress. Large lower actions stay above device/navigation/keyboard insets; the lowest screen edge is not assumed universally comfortable.

**Responsive behavior:** Timeline is vertical on phones and stays vertical on wide windows. Optional detail opens alongside at 960+; long reasons and dates wrap without truncation.

**Recovery and honesty:** Waiting is distinct from approved retry; third-failure/refusal reverse flow is not a rider Return completed button.

<a id="p17"></a>
## P17 — Restricted handover review

**Purpose:** Review a narrowly allowed parcel/cash recovery at the named receiver.

**Scope / owner:** baseline / M08. Narrow backend recovery action; complete receiver evidence remains a prerequisite.

**Enter / next:** P04, P06 → P14, P04, P34, O08. Temporary full-screen workflow covers the tab bar. Back/Close and parcel context stay visible; exiting restores the originating tab and safe draft state.

**Top region:** Recovery handover, authorized parcel and receiving hub.

**Content order:** Reasoned restriction guidance → Returned evidence requirements → Current held parcel/cash summary → Receiver-owned receipt expectation.

**Primary control and placement:** Submit permitted recovery evidence: lower action only when explicitly allowed.

**Secondary controls:** Contact receiver; exit through safe draft handling.

**Color, borders and grouping — why:** Neutral evidence fields and a sand responsibility panel avoid presenting restored approval. Read-only assignment data is not styled as an editable control.

**Theory and thumb reasoning:** Jakob, Hick and error prevention: familiar labelled fields, staged choice and field recovery. Large lower actions stay above device/navigation/keyboard insets; the lowest screen edge is not assumed universally comfortable.

**Responsive behavior:** At 320–599 units use one column; at 600+ center the form at 560 units maximum. At 200% text stack label/action pairs and let the page scroll above the keyboard.

**Recovery and honesty:** Absent capability removes submission; recovery acceptance cannot unlock ordinary operations or self-confirm the receiver's custody.

<a id="p18"></a>
## P18 — Trips

**Purpose:** Find returned records within their real scope and period.

**Scope / owner:** baseline / M11. Scoped/paginated history contract; declared attribution and Philippine dates.

**Enter / next:** root, P14 → P19, O17, O02. Persistent Tasks / Trips / Messages / Profile navigation. Actions are not tabs. Native medium/wide uses a rail when geometry permits.

**Top region:** Trips, period and explicit returned history scope.

**Content order:** Search tracking/address within allowed history → Date/phase filters where returned → Day-grouped records with readable outcome and time → Pagination or Load more with explicit progress.

**Primary control and placement:** Open a trip row: neutral chevron/text affordance; no arbitrary filled page-level action.

**Secondary controls:** Date range O17; clear filters; copy identifier.

**Color, borders and grouping — why:** Borderless grouped rows and subtle separators suit reading many records. A current filter is rose; recorded result badges include text. No invented lifetime rates.

**Theory and thumb reasoning:** Grouping, Hick and recognition: stable categories and labelled rows reduce searching and repeated memory. Large lower actions stay above device/navigation/keyboard insets; the lowest screen edge is not assumed universally comfortable.

**Responsive behavior:** One list column on compact widths. At 960+ use a 300-unit list with detail only when the remaining detail pane is at least 420 units; preserve selection through reflow.

**Recovery and honesty:** No records differs from no matches and a failed page; unavailable pickup/previous-hub history stays disclosed.

<a id="p19"></a>
## P19 — Trip detail and journey

**Purpose:** Review recorded custody and the rider's contribution.

**Scope / owner:** baseline / M11. Recorded checkpoints/history and private proof access.

**Enter / next:** P18, P14, P23 → P20, P16, P37, P06. Parent tab stays selected; compact read/detail views keep the tab bar. Back returns to the actual origin with selection/scroll preserved.

**Top region:** Parcel, phase and recorded outcome.

**Content order:** Saved stop and scope → Chronological custody milestones → Own accepted handoff/evidence when authorized → Separate buyer-confirmation and cash meaning.

**Primary control and placement:** View proof or Open current task when still authorized: neutral lower action.

**Secondary controls:** Copy tracking; expand timestamps and recorded details.

**Color, borders and grouping — why:** Connected timeline groups the journey without a giant full-width map. White record sections are unboxed where headings/dividers suffice; selected context uses rose.

**Theory and thumb reasoning:** Grouping and recognition: connected actual events communicate sequence without inventing progress. Large lower actions stay above device/navigation/keyboard insets; the lowest screen edge is not assumed universally comfortable.

**Responsive behavior:** Timeline is vertical on phones and stays vertical on wide windows. Optional detail opens alongside at 960+; long reasons and dates wrap without truncation.

**Recovery and honesty:** Unavailable milestone has no fake timestamp; a past parcel cannot regain a live mutation; do not expose contacts after access ends.

<a id="p20"></a>
## P20 — Private proof viewer

**Purpose:** Inspect the permitted accepted proof without turning it into public content.

**Scope / owner:** baseline / M11. Authorized private evidence, retention and cleanup policy.

**Enter / next:** P19, P14 → P19, caller. Temporary full-screen workflow covers the tab bar. Back/Close and parcel context stay visible; exiting restores the originating tab and safe draft state.

**Top region:** Close/Back, parcel context and proof time when supplied.

**Content order:** Image with opaque control backplates → Accessible zoom in/out/reset alternatives → Evidence caption and loading/error feedback.

**Primary control and placement:** Close: large reachable control; there is no download/share action by default.

**Secondary controls:** Zoom controls and return to record; gesture zoom is supplementary.

**Color, borders and grouping — why:** Media can use a dark viewing stage with light readable controls; it is not the optional whole-app dark theme. Image bounds and controls are visually separate.

**Theory and thumb reasoning:** Fitts and feedback: accessible media controls and a safe return path accompany gestures. Large lower actions stay above device/navigation/keyboard insets; the lowest screen edge is not assumed universally comfortable.

**Responsive behavior:** Image letterboxes within available space; opaque labelled controls remain reachable in portrait/landscape and at large text. The viewer is a temporary full-screen focus flow.

**Recovery and honesty:** Expired or denied access has a useful return path; no stale previous-account image; an accepted image is not editable here.

<a id="p21"></a>
## P21 — Conversations

**Purpose:** Find the correct parcel-linked person and thread.

**Scope / owner:** baseline / M10. Scoped conversations, phase-bound recipients and read acknowledgement.

**Enter / next:** root, P06 → P22. Persistent Tasks / Trips / Messages / Profile navigation. Actions are not tabs. Native medium/wide uses a rail when geometry permits.

**Top region:** Messages, scoped conversation count and search.

**Content order:** Participant or stored avatar/initials → Parcel reference and Pickup/Delivery phase label → Last message/time and actual unread count → Read-only distinction for ended assignments.

**Primary control and placement:** Open conversation: row with clear name/phase; no New message to arbitrary users.

**Secondary controls:** Search by authorized contact/reference; refresh with feedback.

**Color, borders and grouping — why:** Simple rows use separators rather than nested chat cards; rose marks selection and a small unread badge. Read state is actual data, not decorative dots.

**Theory and thumb reasoning:** Grouping, Hick and recognition: stable categories and labelled rows reduce searching and repeated memory. Large lower actions stay above device/navigation/keyboard insets; the lowest screen edge is not assumed universally comfortable.

**Responsive behavior:** One list column on compact widths. At 960+ use a 300-unit list with detail only when the remaining detail pane is at least 420 units; preserve selection through reflow.

**Recovery and honesty:** An empty list explains when threads appear; network failure does not mark all messages read; selection/drafts survive permitted refresh.

<a id="p22"></a>
## P22 — Conversation thread

**Purpose:** Coordinate this parcel without losing task context.

**Scope / owner:** baseline / M10. Message/read APIs; only displayed selected messages are acknowledged. Composer layout covers root chrome temporarily in compact typing mode.

**Enter / next:** P21, P06 → P06, O15, O18. Parent tab stays selected; compact read/detail views keep the tab bar. Back returns to the actual origin with selection/scroll preserved.

**Top region:** Back to conversations, participant, parcel and phase.

**Content order:** Pinned short parcel/stop context → Scrollable message history → Read-only or read-update failure explanation → Composer with persistent label, character limit and send error.

**Primary control and placement:** Send message: labelled control beside or below composer; reachable above keyboard.

**Secondary controls:** Return to task; editable quick replies remain optional; retry read update is distinct from resending.

**Color, borders and grouping — why:** Sent/received bubbles use neutral and light rose grouping; no saturated red wall of messages. Composer has a visible border and independently reachable Send.

**Theory and thumb reasoning:** Jakob, grouping and feedback: familiar conversation structure, stable parcel context and explicit Send. Large lower actions stay above device/navigation/keyboard insets; the lowest screen edge is not assumed universally comfortable.

**Responsive behavior:** Compact shows one pane; composer moves above the keyboard and the temporary focus view covers bottom navigation. Wide layout uses list/detail when enough width remains, preserving draft and scroll.

**Recovery and honesty:** Switching thread preserves scoped drafts; stale recipient/phase cannot redirect a message; show new-message indicator without forcing scroll away from old content.

<a id="p23"></a>
## P23 — Activity inbox

**Purpose:** Notice durable work, review and cash events missed during a session.

**Scope / owner:** baseline / M12. Backend durable notification resource and fresh own-resource authorization.

**Enter / next:** P05, P25 → P24, P06, P03, P39, O14. Parent tab stays selected; compact read/detail views keep the tab bar. Back returns to the actual origin with selection/scroll preserved.

**Top region:** Activity and actual unread scope.

**Content order:** Time-grouped durable events → Plain event title, parcel/subject and timestamp → Read/unread status paired with text or icon → Useful authorized destination.

**Primary control and placement:** Open event: neutral row action, not an unsupported bulk mark-all control.

**Secondary controls:** Individual read actions O14 when supported; refresh.

**Color, borders and grouping — why:** Unboxed rows use grouping for chronology; rose emphasis is reserved for unread selection, and event kinds use modest semantic icons.

**Theory and thumb reasoning:** Grouping, Hick and recognition: stable categories and labelled rows reduce searching and repeated memory. Large lower actions stay above device/navigation/keyboard insets; the lowest screen edge is not assumed universally comfortable.

**Responsive behavior:** One list column on compact widths. At 960+ use a 300-unit list with detail only when the remaining detail pane is at least 420 units; preserve selection through reflow.

**Recovery and honesty:** Unknown/delayed event remains readable without guessing a route; failed read update does not claim success; unavailable notice API is S11.

<a id="p24"></a>
## P24 — Activity detail

**Purpose:** Read a notice and find the actual current action.

**Scope / owner:** baseline / M12. Durable event details, accepted links and current capability.

**Enter / next:** P23 → P06, P03, P39, P34. Parent tab stays selected; compact read/detail views keep the tab bar. Back returns to the actual origin with selection/scroll preserved.

**Top region:** Event title and supplied time.

**Content order:** Event explanation and relevant reference → Current availability of the linked resource → Next responsible actor if known.

**Primary control and placement:** Open authorized destination: lower neutral or contextual primary only if real work is available.

**Secondary controls:** Back to Activity; Mark read only through the accepted own-event action.

**Color, borders and grouping — why:** Most notices are neutral text; a sand or mint inset follows actual event meaning. An old event does not get a live-action badge merely because it was unread.

**Theory and thumb reasoning:** Recognition, grouping and progressive disclosure: key facts and one relevant action precede secondary records. Large lower actions stay above device/navigation/keyboard insets; the lowest screen edge is not assumed universally comfortable.

**Responsive behavior:** Compact uses labelled definition rows and readable wrapping. Wide can pair a related panel with the main column, never stretching a form or duplicating the action.

**Recovery and honesty:** Denied/removed target keeps a safe explanation; event history never overrides current authorization.

<a id="p25"></a>
## P25 — Profile

**Purpose:** Find identity, assignment and useful account actions.

**Scope / owner:** baseline / M13. Own identity/profile and managed placement resource.

**Enter / next:** root → P26, P27, P28, P29, P37. Persistent Tasks / Trips / Messages / Profile navigation. Actions are not tabs. Native medium/wide uses a rail when geometry permits.

**Top region:** Actual avatar/initials, name and reviewed status; modest cover motif.

**Content order:** Actual account/contact summary → Company, hub and barangay with absent-value wording → Rows for Information, Assignment, Vehicle, Settings and Cash when available.

**Primary control and placement:** Edit contact details: neutral labelled action after contact summary.

**Secondary controls:** Open managed records and settings; unsupported cash shows availability guidance rather than a wallet balance.

**Color, borders and grouping — why:** A quiet cover adds identity without a credential/pass graphic. Rows are largely borderless with chevrons; review badge uses actual state and dark text.

**Theory and thumb reasoning:** Recognition and grouping: real identity and managed records are separated from editable contact actions. Large lower actions stay above device/navigation/keyboard insets; the lowest screen edge is not assumed universally comfortable.

**Responsive behavior:** Compact stacks identity and settings rows; wide uses a modest identity column and details. Avatar/cover stays small when text increases; private fields do not become decorative cards.

**Recovery and honesty:** No default license, hours or hub; profile review and working eligibility stay separate; avatar editing is not added without a supported contract.

<a id="p26"></a>
## P26 — Edit contact information

**Purpose:** Save only permitted contact fields with clear validation.

**Scope / owner:** baseline / M13. Shared profile validators and permitted self-service fields.

**Enter / next:** P25 → P25, O08. Temporary full-screen workflow covers the tab bar. Back/Close and parcel context stay visible; exiting restores the originating tab and safe draft state.

**Top region:** Edit information, Back and current field purpose.

**Content order:** Permitted name and mobile fields → Persistent labels and actual format guidance → Inline field errors and saved acknowledgement.

**Primary control and placement:** Save contact details: full-width lower red action.

**Secondary controls:** Discard/back through O08 if changed; read-only reviewed identity fields link to guidance.

**Color, borders and grouping — why:** Outlined inputs mean editable data; one white form surface groups the fields. Managed identity/placement is visually read-only rather than disabled-looking editable inputs.

**Theory and thumb reasoning:** Jakob, Hick and error prevention: familiar labelled fields, staged choice and field recovery. Large lower actions stay above device/navigation/keyboard insets; the lowest screen edge is not assumed universally comfortable.

**Responsive behavior:** At 320–599 units use one column; at 600+ center the form at 560 units maximum. At 200% text stack label/action pairs and let the page scroll above the keyboard.

**Recovery and honesty:** Rejected edits preserve safe text; duplicate save is blocked; fresh saved values replace drafts only after acceptance.

<a id="p27"></a>
## P27 — Assignment and hub directory

**Purpose:** Know where the rider works and how to reach the authorized hub.

**Scope / owner:** baseline / M13. Own managed placement and permitted hub-directory fields; new receiving instructions need agreement.

**Enter / next:** P25, P06 → P10, P34, O12. Parent tab stays selected; compact read/detail views keep the tab bar. Back returns to the actual origin with selection/scroll preserved.

**Top region:** Company and assigned hub; area when configured.

**Content order:** Read-only hub/area fields → Authorized address and contact → Receiving information only when supplied → Who handles placement corrections.

**Primary control and placement:** Directions to this hub: lower neutral action with an actual destination.

**Secondary controls:** Call permitted hub contact; ask for correction through supported guidance.

**Color, borders and grouping — why:** A white grouping surface separates assignment from operational work; fields have no input outlines because they cannot be edited here.

**Theory and thumb reasoning:** Recognition, grouping and progressive disclosure: key facts and one relevant action precede secondary records. Large lower actions stay above device/navigation/keyboard insets; the lowest screen edge is not assumed universally comfortable.

**Responsive behavior:** Compact uses labelled definition rows and readable wrapping. Wide can pair a related panel with the main column, never stretching a form or duplicating the action.

**Recovery and honesty:** Unassigned/missing address and contact are explicit; no guessed operating hours; absent barangay does not claim strict area-only coverage.

<a id="p28"></a>
## P28 — Vehicle and credentials

**Purpose:** Read accurate managed vehicle/license information.

**Scope / owner:** baseline / M13. Managed vehicle data and field-level/private document permission.

**Enter / next:** P25 → P34. Parent tab stays selected; compact read/detail views keep the tab bar. Back returns to the actual origin with selection/scroll preserved.

**Top region:** Vehicle and credentials; logistics-managed explanation.

**Content order:** Stored type/model/plate → License and registration status from actual fields → Permitted private document link only if supplied → Correction guidance.

**Primary control and placement:** Contact responsible team: neutral guidance action when a real contact exists.

**Secondary controls:** Back to Profile; reveal only authorized private evidence.

**Color, borders and grouping — why:** Definition rows and quiet dividers make read-only facts easy to scan. No fake verification seal, barcode, uniform license restrictions or decorative pass.

**Theory and thumb reasoning:** Recognition, grouping and progressive disclosure: key facts and one relevant action precede secondary records. Large lower actions stay above device/navigation/keyboard insets; the lowest screen edge is not assumed universally comfortable.

**Responsive behavior:** Compact uses labelled definition rows and readable wrapping. Wide can pair a related panel with the main column, never stretching a form or duplicating the action.

**Recovery and honesty:** Not provided is different from verified; expired or unknown state is plain text; no rider-owned fleet/credential editing.

<a id="p29"></a>
## P29 — Settings

**Purpose:** Find supported preferences, security and help without a crowded menu.

**Scope / owner:** baseline / M14. Accepted account actions; optional preferences remain their own design scope.

**Enter / next:** P25 → P30, P32, P35, P36, P43, P48, O09. Parent tab stays selected; compact read/detail views keep the tab bar. Back returns to the actual origin with selection/scroll preserved.

**Top region:** Settings and Back.

**Content order:** Account/security group → Device access group → Supported preferences only → Help, Privacy and About group → Sign out as a separated action.

**Primary control and placement:** No general primary button; each setting row opens its named destination.

**Secondary controls:** Sign out uses O09; optional controls appear only after actual support exists.

**Color, borders and grouping — why:** Borderless rows with group dividers avoid a box around every preference. Sign out is labelled and separated, not colored like destructive account closure.

**Theory and thumb reasoning:** Grouping, Hick and recognition: stable categories and labelled rows reduce searching and repeated memory. Large lower actions stay above device/navigation/keyboard insets; the lowest screen edge is not assumed universally comfortable.

**Responsive behavior:** One list column on compact widths. At 960+ use a 300-unit list with detail only when the remaining detail pane is at least 420 units; preserve selection through reflow.

**Recovery and honesty:** Unavailable options explain or stay absent; no no-op switches or developer/API configuration in the rider menu.

<a id="p30"></a>
## P30 — Privacy and security

**Purpose:** Understand verification and change the password safely.

**Scope / owner:** baseline / M14. Email verification, password policy and controlled closure authority.

**Enter / next:** P29 → P31, E08, P35, P47, O09. Parent tab stays selected; compact read/detail views keep the tab bar. Back returns to the actual origin with selection/scroll preserved.

**Top region:** Privacy and security.

**Content order:** Real email-verification status → Password-change row and requirements → Privacy notice link → Account-closure guidance when needed.

**Primary control and placement:** Change password: neutral row leading to the focused form.

**Secondary controls:** Verify email opens the supported first-party flow; sign out remains explicit.

**Color, borders and grouping — why:** Status is a small labelled inset; rows and explanatory text remain neutral. There is no generic green Secure account promise or artificial security score.

**Theory and thumb reasoning:** Recognition, grouping and progressive disclosure: key facts and one relevant action precede secondary records. Large lower actions stay above device/navigation/keyboard insets; the lowest screen edge is not assumed universally comfortable.

**Responsive behavior:** Compact uses labelled definition rows and readable wrapping. Wide can pair a related panel with the main column, never stretching a form or duplicating the action.

**Recovery and honesty:** Unverified email shows the actual prerequisite; unsupported device-session lists are not invented; closure cannot abandon held parcels/cash.

<a id="p31"></a>
## P31 — Change password

**Purpose:** Change credentials without obscuring requirements or losing errors.

**Scope / owner:** baseline / M14. Accepted password/session policy; actual length constraints from the server.

**Enter / next:** P30 → P30, P01, O08. Temporary full-screen workflow covers the tab bar. Back/Close and parcel context stay visible; exiting restores the originating tab and safe draft state.

**Top region:** Change password, Back and verified-email prerequisite.

**Content order:** Current/new/confirmation inputs with persistent labels → Password manager/autofill and paste support → Show/hide controls with accessible names → Requirement and validation text.

**Primary control and placement:** Update password: lower red submit with pending feedback.

**Secondary controls:** Back/discard through O08; recovery via approved entry if necessary.

**Color, borders and grouping — why:** Clear filled fields and a single submit focus on the task; requirements are text, not a misleading strength gauge unsupported by policy.

**Theory and thumb reasoning:** Jakob, Hick and error prevention: familiar labelled fields, staged choice and field recovery. Large lower actions stay above device/navigation/keyboard insets; the lowest screen edge is not assumed universally comfortable.

**Responsive behavior:** At 320–599 units use one column; at 600+ center the form at 560 units maximum. At 200% text stack label/action pairs and let the page scroll above the keyboard.

**Recovery and honesty:** Field failure retains permitted state but success clears sensitive values; revocation/expiry follows the real session policy.

<a id="p32"></a>
## P32 — Help center

**Purpose:** Find a useful next step for field and account problems.

**Scope / owner:** baseline / M14. Approved help content/contact routes; static instructions must match current flow.

**Enter / next:** P29, P06, P03 → P33, P34, P46. Parent tab stays selected; compact read/detail views keep the tab bar. Back returns to the actual origin with selection/scroll preserved.

**Top region:** Help, search or clear topic grouping.

**Content order:** Pickup and hub handoff topics → Delivery/proof/cash topics → Access and application topics → Contact the correct supported team.

**Primary control and placement:** Open topic or Contact help: neutral rows; context can carry the active parcel.

**Secondary controls:** How Rider works is P46 if selected; permission guidance links P48.

**Color, borders and grouping — why:** Readable category headings and rows are calmer than colored feature tiles. A current problem may use one sand instruction inset.

**Theory and thumb reasoning:** Grouping, Hick and recognition: stable categories and labelled rows reduce searching and repeated memory. Large lower actions stay above device/navigation/keyboard insets; the lowest screen edge is not assumed universally comfortable.

**Responsive behavior:** One list column on compact widths. At 960+ use a 300-unit list with detail only when the remaining detail pane is at least 420 units; preserve selection through reflow.

**Recovery and honesty:** No invented support hours, emergency service or response guarantee; offline known guidance stays distinct from unavailable live help.

<a id="p33"></a>
## P33 — Help guide

**Purpose:** Understand one task or recovery procedure in plain language.

**Scope / owner:** baseline / M14. Reviewed help guidance and the actual capability of the linked task.

**Enter / next:** P32, P02 → P34, P06, P48. Parent tab stays selected; compact read/detail views keep the tab bar. Back returns to the actual origin with selection/scroll preserved.

**Top region:** Guide title and Back.

**Content order:** Short situation statement → Numbered permitted steps → Relevant field/evidence examples → Useful contact or related task link.

**Primary control and placement:** Open relevant task or Contact help: neutral lower link if authorized.

**Secondary controls:** Related guide links below the steps.

**Color, borders and grouping — why:** Unboxed reading content, aligned steps and one caution inset improve grouping. Decorative illustrations never resemble a real proof or credential.

**Theory and thumb reasoning:** Grouping, progressive disclosure and recognition: readable instructions before optional detail. Large lower actions stay above device/navigation/keyboard insets; the lowest screen edge is not assumed universally comfortable.

**Responsive behavior:** Reading column is at most 680 units and wraps at 320. Wide windows can show a contents rail; keyboard focus and large text preserve reading order.

**Recovery and honesty:** Guidance cannot enable unsupported actions; stale version wording is updated with the owning flow; no dense legal wall above steps.

<a id="p34"></a>
## P34 — Contact help with parcel context

**Purpose:** Prepare useful context and contact an actual authorized help channel.

**Scope / owner:** baseline / M14. Real contacts/approved help path; ticketing or incident persistence is outside this baseline.

**Enter / next:** P32, P06, P04 → O19, O12, P22. Parent tab stays selected; compact read/detail views keep the tab bar. Back returns to the actual origin with selection/scroll preserved.

**Top region:** Help for this parcel or account.

**Content order:** Selected authorized parcel/reference → Short problem summary for the rider to review → Available contact/channel and truthful availability → Copy safe context if supported.

**Primary control and placement:** Open supported contact channel: lower labelled neutral action.

**Secondary controls:** Choose another owned parcel using O19; keep sensitive proof out of copied context.

**Color, borders and grouping — why:** Read-only context is unboxed; any editable summary has a soft fill and accent focus indicator. No fake ticket number or claim that a safety agent is monitoring.

**Theory and thumb reasoning:** Recognition, grouping and progressive disclosure: key facts and one relevant action precede secondary records. Large lower actions stay above device/navigation/keyboard insets; the lowest screen edge is not assumed universally comfortable.

**Responsive behavior:** Compact uses labelled definition rows and readable wrapping. Wide can pair a related panel with the main column, never stretching a form or duplicating the action.

**Recovery and honesty:** No configured channel means guidance rather than a dead button; submitted reports are not implied by copying or opening contact.

<a id="p35"></a>
## P35 — Privacy notice

**Purpose:** Read the current provided data-handling notice.

**Scope / owner:** baseline / M14. Approved notice text; this design does not establish retention or legal commitments.

**Enter / next:** P29, P30 → P34. Parent tab stays selected; compact read/detail views keep the tab bar. Back returns to the actual origin with selection/scroll preserved.

**Top region:** Privacy, document version/date when supplied.

**Content order:** Readable sections with contents links → Actual data-use and contact wording → Authorized policy contact.

**Primary control and placement:** No required accept button for reading an existing notice; Return is the main navigation.

**Secondary controls:** Copy/open an approved policy link if supported.

**Color, borders and grouping — why:** Neutral reading canvas and headings support scanning; no decorative colored legal cards or hidden consent choices.

**Theory and thumb reasoning:** Grouping, progressive disclosure and recognition: readable instructions before optional detail. Large lower actions stay above device/navigation/keyboard insets; the lowest screen edge is not assumed universally comfortable.

**Responsive behavior:** Reading column is at most 680 units and wraps at 320. Wide windows can show a contents rail; keyboard focus and large text preserve reading order.

**Recovery and honesty:** Unavailable/version-missing content is honest; draft policy copy is not represented as approved legal guidance.

<a id="p36"></a>
## P36 — About Rider

**Purpose:** Understand the app, supported version and how it fits the parcel flow.

**Scope / owner:** baseline / M14. Public app metadata and approved support/distribution information.

**Enter / next:** P29 → P32, P46. Parent tab stays selected; compact read/detail views keep the tab bar. Back returns to the actual origin with selection/scroll preserved.

**Top region:** BagooPH Rider with a small original parcel motif.

**Content order:** Actual app version and release label → Short Rider purpose → Help/privacy links → Update guidance only when an actual distribution link exists.

**Primary control and placement:** Help: neutral lower link when needed; no forced decorative button.

**Secondary controls:** Read How Rider works if available.

**Color, borders and grouping — why:** A modest identity moment is appropriate on a low-frequency reading page. White surface and dark text remain consistent with operational screens.

**Theory and thumb reasoning:** Grouping, progressive disclosure and recognition: readable instructions before optional detail. Large lower actions stay above device/navigation/keyboard insets; the lowest screen edge is not assumed universally comfortable.

**Responsive behavior:** Reading column is at most 680 units and wraps at 320. Wide windows can show a contents rail; keyboard focus and large text preserve reading order.

**Recovery and honesty:** Build/version is actual data; no fake uptime, network endpoint, debug settings or automatically available update button.

<a id="p37"></a>
## P37 — Cash responsibility overview

**Purpose:** Separate cash held, received remittance, discrepancy and earnings.

**Scope / owner:** baseline / M15. Accepted append-only finance resource and matching rider/hub/admin records.

**Enter / next:** P25, P14, P19 → P38, P39, P40, P41, O16. Parent tab stays selected; compact read/detail views keep the tab bar. Back returns to the actual origin with selection/scroll preserved.

**Top region:** Cash responsibility and covered scope/period.

**Content order:** Authoritative cash still held → Hub-received remittance records → Discrepancy/reconciliation meaning → Confirmed earnings as a separate destination.

**Primary control and placement:** View remittance instructions: lower neutral or contextual action when a real duty exists.

**Secondary controls:** Open receipts, discrepancies and explanation O16.

**Color, borders and grouping — why:** Amounts are dark and labelled in white groups; no saturated Wallet balance tile. Sand marks an actual unresolved responsibility, mint an actual receipt.

**Theory and thumb reasoning:** Recognition and error prevention: clear amount meanings and labelled review precede any accepted financial action. Large lower actions stay above device/navigation/keyboard insets; the lowest screen edge is not assumed universally comfortable.

**Responsive behavior:** Currency and labels stay together on phones; two columns are allowed only for independent groups on wide windows. At 200% text put amount underneath its label.

**Recovery and honesty:** No ledger support means Unavailable, not zero; missing amount/period stays explicit; delivery itself does not remit money.

<a id="p38"></a>
## P38 — Remittance instructions

**Purpose:** Know the actual receiving point and required handover evidence.

**Scope / owner:** baseline / M15. Approved remittance contract and receiver evidence; no guessed payment channel.

**Enter / next:** P37 → P27, P39, P34. Parent tab stays selected; compact read/detail views keep the tab bar. Back returns to the actual origin with selection/scroll preserved.

**Top region:** Remit cash, supplied amount and receiving hub.

**Content order:** Exact outstanding amount from the ledger → Authorized receiver/address/contact → Accepted evidence/instruction → Receiver-owned confirmation expectation.

**Primary control and placement:** Open receiving directions or permitted remittance action: labelled lower action only if accepted.

**Secondary controls:** Contact receiver; view prior receipt.

**Color, borders and grouping — why:** One responsibility group uses white or sand; read-only amounts have no input appearance. A rider acknowledgement is never styled as Hub received.

**Theory and thumb reasoning:** Recognition, grouping and progressive disclosure: key facts and one relevant action precede secondary records. Large lower actions stay above device/navigation/keyboard insets; the lowest screen edge is not assumed universally comfortable.

**Responsive behavior:** Compact uses labelled definition rows and readable wrapping. Wide can pair a related panel with the main column, never stretching a form or duplicating the action.

**Recovery and honesty:** Unavailable receiver/action has a reason; no arbitrary top-up or transfer method; uncertain submission reconciles before retry.

<a id="p39"></a>
## P39 — Remittance receipt

**Purpose:** Inspect a hub-confirmed cash receipt and its separate reconciliation state.

**Scope / owner:** baseline / M15. Hub-confirmed receipt resource and scoped finance evidence.

**Enter / next:** P37, P38, P24 → P37, P40. Parent tab stays selected; compact read/detail views keep the tab bar. Back returns to the actual origin with selection/scroll preserved.

**Top region:** Receipt reference, recorded receiver and time.

**Content order:** Confirmed received amount → Linked collection records when supplied → Reconciliation state and any remaining difference.

**Primary control and placement:** Back to cash responsibility: neutral lower action.

**Secondary controls:** Open discrepancy or related record if authorized.

**Color, borders and grouping — why:** A small mint received inset is separate from neutral reconciliation rows; green receipt does not mean seller paid.

**Theory and thumb reasoning:** Feedback and distinctiveness: the confirmed outcome is specific and the next action is calm. Large lower actions stay above device/navigation/keyboard insets; the lowest screen edge is not assumed universally comfortable.

**Responsive behavior:** One centered receipt column on compact and wide windows, 680-unit maximum. Extra detail can expand below, while the recorded status stays near the heading.

**Recovery and honesty:** Pending reconciliation remains pending; missing signature/reference is not fabricated; no editable receipt or false downloadable statement.

<a id="p40"></a>
## P40 — Cash discrepancy detail

**Purpose:** Understand the recorded difference and the authorized resolution path.

**Scope / owner:** baseline / M15. Accepted discrepancy/correction resource and owning review authority.

**Enter / next:** P37, P39 → P34, P39. Parent tab stays selected; compact read/detail views keep the tab bar. Back returns to the actual origin with selection/scroll preserved.

**Top region:** Recorded discrepancy and related parcel/receipt.

**Content order:** Expected versus received amounts from records → Supplied reason and current reviewer/action → Append-only correction history when returned.

**Primary control and placement:** Open approved review/contact path: lower neutral action.

**Secondary controls:** Back to receipt or cash responsibility.

**Color, borders and grouping — why:** Dark numeric labels and a sand reason inset give clarity without implying blame. Timeline rows show recorded corrections rather than editable balances.

**Theory and thumb reasoning:** Grouping and recognition: connected actual events communicate sequence without inventing progress. Large lower actions stay above device/navigation/keyboard insets; the lowest screen edge is not assumed universally comfortable.

**Responsive behavior:** Timeline is vertical on phones and stays vertical on wide windows. Optional detail opens alongside at 960+; long reasons and dates wrap without truncation.

**Recovery and honesty:** Unknown resolution stays unknown; no frontend edit of ledger history or manufactured reconciled amount.

<a id="p41"></a>
## P41 — Confirmed earnings

**Purpose:** See only approved rider earnings for the returned period.

**Scope / owner:** baseline / M15. Confirmed final-mile attribution and accepted earning records; withdrawal is excluded.

**Enter / next:** P25, P37 → P42, O17. Parent tab stays selected; compact read/detail views keep the tab bar. Back returns to the actual origin with selection/scroll preserved.

**Top region:** Confirmed earnings and actual period.

**Content order:** Recorded total and explicit coverage → Per-delivery entries and adjustments → Clear separation from COD held → Date filter only where data supports it.

**Primary control and placement:** Open earning record: neutral row action; no Withdraw button.

**Secondary controls:** Date range O17; cash responsibilities remain a separate link.

**Color, borders and grouping — why:** Neutral totals and restrained bars support reading; a small accent can select the period. Earnings are not shown as COD cash or guessed fixed-rate totals.

**Theory and thumb reasoning:** Recognition and error prevention: clear amount meanings and labelled review precede any accepted financial action. Large lower actions stay above device/navigation/keyboard insets; the lowest screen edge is not assumed universally comfortable.

**Responsive behavior:** Currency and labels stay together on phones; two columns are allowed only for independent groups on wide windows. At 200% text put amount underneath its label.

**Recovery and honesty:** Missing earning policy/resource is unavailable; absent history is not lifetime zero; no estimated amount labelled paid.

<a id="p42"></a>
## P42 — Earning record detail

**Purpose:** Understand the recorded source of one earning amount.

**Scope / owner:** baseline / M15. Accepted per-record earning fields and private ownership scope.

**Enter / next:** P41 → P19, P41. Parent tab stays selected; compact read/detail views keep the tab bar. Back returns to the actual origin with selection/scroll preserved.

**Top region:** Recorded earning amount and parcel/event.

**Content order:** Supplied earning components and adjustments → Recorded status/time and attribution → Related delivery reference.

**Primary control and placement:** Open related trip: neutral lower link.

**Secondary controls:** Return to earnings; copy the reference if supported.

**Color, borders and grouping — why:** Definition rows with aligned currency values use quiet dividers; no decorative green payout seal or unrelated product commission breakdown.

**Theory and thumb reasoning:** Recognition, grouping and progressive disclosure: key facts and one relevant action precede secondary records. Large lower actions stay above device/navigation/keyboard insets; the lowest screen edge is not assumed universally comfortable.

**Responsive behavior:** Compact uses labelled definition rows and readable wrapping. Wide can pair a related panel with the main column, never stretching a form or duplicating the action.

**Recovery and honesty:** Unknown component/rate is not inferred; adjustments keep their actual source and state.

<a id="p43"></a>
## P43 — Comfort preferences

**Purpose:** Choose only supported local comfort options and see a real preview.

**Scope / owner:** optional / M14. Optional preference implementation and real persistence/accessibility verification.

**Enter / next:** P29 → P44, P45. Parent tab stays selected; compact read/detail views keep the tab bar. Back returns to the actual origin with selection/scroll preserved.

**Top region:** Preferences with a live readable sample.

**Content order:** System text-size guidance or implemented app preference → Supported navigation preference → Language/theme entries only after those features exist → Optional motion/haptic control only if implemented.

**Primary control and placement:** No generic Save unless changes require it; each preference must visibly work.

**Secondary controls:** Open language/appearance; restore device defaults only if supported.

**Color, borders and grouping — why:** Borderless rows and a neutral preview avoid a collection of nonfunctional switches. The preview demonstrates consequences before choice.

**Theory and thumb reasoning:** Grouping, Hick and recognition: stable categories and labelled rows reduce searching and repeated memory. Large lower actions stay above device/navigation/keyboard insets; the lowest screen edge is not assumed universally comfortable.

**Responsive behavior:** One list column on compact widths. At 960+ use a 300-unit list with detail only when the remaining detail pane is at least 420 units; preserve selection through reflow.

**Recovery and honesty:** Unsupported controls are absent or clearly explained; preferences cannot affect permission, assignment or duty.

<a id="p44"></a>
## P44 — Language preference

**Purpose:** Choose among actually completed translations.

**Scope / owner:** optional / M14. Optional complete translation/content QA; English/Filipino are candidates, not implemented claims.

**Enter / next:** P43 → P43. Parent tab stays selected; compact read/detail views keep the tab bar. Back returns to the actual origin with selection/scroll preserved.

**Top region:** Language with current selection.

**Content order:** Supported language names in their own language → Radio selection and sample instruction → Effect on interface text, not operational codes.

**Primary control and placement:** Apply language: lower red action only when a change exists.

**Secondary controls:** Cancel keeps the current language.

**Color, borders and grouping — why:** A rose selected row plus radio/text makes selection visible; other options are neutral, readable and large.

**Theory and thumb reasoning:** Hick, Fitts and feedback: a small set of real choices, large targets and a preview of the consequence. Large lower actions stay above device/navigation/keyboard insets; the lowest screen edge is not assumed universally comfortable.

**Responsive behavior:** Options stack at 320 and 200% text. Wider layouts may put a sample beside the options; radio labels retain 48-unit touch regions.

**Recovery and honesty:** No option for an incomplete translation; long labels and pluralization are checked; no silent translation of server failure codes.

<a id="p45"></a>
## P45 — Appearance preference

**Purpose:** Preview and select only implemented appearance choices.

**Scope / owner:** optional / M14. Optional complete palette/component implementation and contrast verification.

**Enter / next:** P43 → P43. Parent tab stays selected; compact read/detail views keep the tab bar. Back returns to the actual origin with selection/scroll preserved.

**Top region:** Appearance and small actual screen sample.

**Content order:** System/light/dark choices if all supported → Readable previews and contrast explanation → Reduced-transparency/motion follows device support.

**Primary control and placement:** Apply appearance: lower red action for a real change.

**Secondary controls:** Cancel preserves the current appearance.

**Color, borders and grouping — why:** The sample explains background/text/control changes; selection uses a radio and rose marker rather than relying on a color swatch alone.

**Theory and thumb reasoning:** Hick, Fitts and feedback: a small set of real choices, large targets and a preview of the consequence. Large lower actions stay above device/navigation/keyboard insets; the lowest screen edge is not assumed universally comfortable.

**Responsive behavior:** Options stack at 320 and 200% text. Wider layouts may put a sample beside the options; radio labels retain 48-unit touch regions.

**Recovery and honesty:** Dark appearance is a proposal until every component/state is checked; no instant appearance claim from a lone toggle.

<a id="p46"></a>
## P46 — How Rider works tour

**Purpose:** Learn the two work phases and how the selected tools help.

**Scope / owner:** optional / M14. Optional static tour selection; no native onboarding/API claim.

**Enter / next:** P32, P36 → P32, P05. Temporary full-screen workflow covers the tab bar. Back/Close and parcel context stay visible; exiting restores the originating tab and safe draft state.

**Top region:** How Rider works, step indicator and Skip.

**Content order:** Seller-to-origin-hub pickup → Hub-assigned final-mile delivery → Parcel Finder and Doorstep Guide explanation → Cash and receipt meaning.

**Primary control and placement:** Next / Finish: lower reachable red action.

**Secondary controls:** Skip and Close are labelled; never gate work behind a decorative tour.

**Color, borders and grouping — why:** Simple vector motifs and quiet pages suit introductory learning; no pretend interactive scanner or completion event.

**Theory and thumb reasoning:** Grouping, progressive disclosure and recognition: readable instructions before optional detail. Large lower actions stay above device/navigation/keyboard insets; the lowest screen edge is not assumed universally comfortable.

**Responsive behavior:** Reading column is at most 680 units and wraps at 320. Wide windows can show a contents rail; keyboard focus and large text preserve reading order.

**Recovery and honesty:** Tour remains revisitable; skipping never changes approval; permissions are requested during the actual task rather than all at onboarding.

<a id="p47"></a>
## P47 — Account closure guidance

**Purpose:** Explain the controlled path when a rider wants to close the account.

**Scope / owner:** conditional / M14. Controlled closure/help policy; self-service deletion is not baseline functionality.

**Enter / next:** P30, P33 → P34. Parent tab stays selected; compact read/detail views keep the tab bar. Back returns to the actual origin with selection/scroll preserved.

**Top region:** Account closure and responsibility explanation.

**Content order:** Active parcel/cash duties when authorized → Who can review the request → Supported contact path and retained-record explanation from policy.

**Primary control and placement:** Contact authorized management: neutral lower action if a real route exists.

**Secondary controls:** Return to security; sign out remains separate.

**Color, borders and grouping — why:** A restrained warning inset explains consequences; no red Delete account button when a guarded request contract is unavailable.

**Theory and thumb reasoning:** Grouping, progressive disclosure and recognition: readable instructions before optional detail. Large lower actions stay above device/navigation/keyboard insets; the lowest screen edge is not assumed universally comfortable.

**Responsive behavior:** Reading column is at most 680 units and wraps at 320. Wide windows can show a contents rail; keyboard focus and large text preserve reading order.

**Recovery and honesty:** No client-only closure, role conversion or silent abandonment of custody; policy wording is supplied rather than invented.

<a id="p48"></a>
## P48 — Device access and permissions

**Purpose:** Understand actual camera/media/navigation access and how to recover denial.

**Scope / owner:** baseline / M14. Actual native permission/launcher adapters and real-device checks.

**Enter / next:** P29, P07 → Z01, P07. Parent tab stays selected; compact read/detail views keep the tab bar. Back returns to the actual origin with selection/scroll preserved.

**Top region:** Device access with accurate permission states.

**Content order:** Camera permission and the tasks that need it → Media access/picker guidance by device behavior → Location row only if an included feature actually needs it → Open device settings when supported.

**Primary control and placement:** Open device settings or Retry camera: lower labelled neutral action appropriate to the state.

**Secondary controls:** Return to the originating scan/proof task.

**Color, borders and grouping — why:** Permission rows have status text/icons and no fake app-owned OS toggles. Neutral surfaces distinguish information from a real permission request.

**Theory and thumb reasoning:** Recognition, grouping and progressive disclosure: key facts and one relevant action precede secondary records. Large lower actions stay above device/navigation/keyboard insets; the lowest screen edge is not assumed universally comfortable.

**Responsive behavior:** Compact uses labelled definition rows and readable wrapping. Wide can pair a related panel with the main column, never stretching a form or duplicating the action.

**Recovery and honesty:** Denied/permanently denied/restricted are distinct; OS settings return refetches status; saved-stop navigation does not automatically require live GPS.

<a id="e01"></a>
## E01 — Application: rider information

**Purpose:** Enter real registration/contact and operating-area fields.

**Scope / owner:** external / M03. Existing first-party web flow; native equivalent needs separate API scope.

**Enter / next:** P02 → E02, P01. No operational navigation before fresh authorized entry. Back/recovery/application links retain their real purpose.

**Top region:** Rider information, Step 1 of 3.

**Content order:** Name, birthday with current age policy → Email and Philippine mobile field → Address and operating-area selectors as supported.

**Primary control and placement:** Continue to vehicle: after the form.

**Secondary controls:** Back to sign in; inline help near the field.

**Color, borders and grouping — why:** One red continuation and softly filled fields clarify the sequence; the stepper is navigation context rather than verification.

**Theory and thumb reasoning:** Jakob, Hick and error prevention: familiar labelled fields, staged choice and field recovery. Large lower actions stay above device/navigation/keyboard insets; the lowest screen edge is not assumed universally comfortable.

**Responsive behavior:** At 320–599 units use one column; at 600+ center the form at 560 units maximum. At 200% text stack label/action pairs and let the page scroll above the keyboard.

**Recovery and honesty:** Field errors focus the first issue and preserve safe data; birth date cannot be replaced by a self-declared adult checkbox.

<a id="e02"></a>
## E02 — Application: vehicle information

**Purpose:** Provide the vehicle/license identifiers required by the current application.

**Scope / owner:** external / M03. Existing first-party web flow; native equivalent needs separate API scope.

**Enter / next:** E01 → E03, E01. No operational navigation before fresh authorized entry. Back/recovery/application links retain their real purpose.

**Top region:** Vehicle information, Step 2 of 3.

**Content order:** Supported vehicle-type choice → Plate or registration reference according to policy → License reference and field guidance.

**Primary control and placement:** Continue to documents: lower action.

**Secondary controls:** Back retains allowed field data.

**Color, borders and grouping — why:** Vehicle choices are labelled radio/cards with real selected state; quiet forms avoid turning every type into a saturated tile.

**Theory and thumb reasoning:** Jakob, Hick and error prevention: familiar labelled fields, staged choice and field recovery. Large lower actions stay above device/navigation/keyboard insets; the lowest screen edge is not assumed universally comfortable.

**Responsive behavior:** At 320–599 units use one column; at 600+ center the form at 560 units maximum. At 200% text stack label/action pairs and let the page scroll above the keyboard.

**Recovery and honesty:** Actual permitted type/identifier rules apply; no guessed licensed status.

<a id="e03"></a>
## E03 — Application: documents and password

**Purpose:** Review required private documents and credentials before submission.

**Scope / owner:** external / M03. Existing first-party web flow; native equivalent needs separate API scope.

**Enter / next:** E02 → E04, E05, E02. No operational navigation before fresh authorized entry. Back/recovery/application links retain their real purpose.

**Top region:** Documents, Step 3 of 3.

**Content order:** Identity/license/registration uploads with preview and replace/remove → Policy-supplied allowed limits → Password/confirmation with autofill → Explicit application submission wording.

**Primary control and placement:** Submit application: after requirements and review.

**Secondary controls:** Back, replace/remove and recovery help are secondary.

**Color, borders and grouping — why:** Upload regions have discoverable borders; one red submit contrasts with neutral source controls. Upload selection is not approval.

**Theory and thumb reasoning:** Jakob, Hick and error prevention: familiar labelled fields, staged choice and field recovery. Large lower actions stay above device/navigation/keyboard insets; the lowest screen edge is not assumed universally comfortable.

**Responsive behavior:** At 320–599 units use one column; at 600+ center the form at 560 units maximum. At 200% text stack label/action pairs and let the page scroll above the keyboard.

**Recovery and honesty:** Interrupted/rejected uploads retain only safe allowed drafts; password values follow secure cleanup.

<a id="e04"></a>
## E04 — Email-code verification panel

**Purpose:** Complete the existing registration or recovery email challenge.

**Scope / owner:** external / M03. Existing first-party web flow; native equivalent needs separate API scope.

**Enter / next:** E03, E06 → E05, E07, caller. No operational navigation before fresh authorized entry. Back/recovery/application links retain their real purpose.

**Top region:** Verify email and masked supplied address.

**Content order:** One accessible code input supporting full paste/autofill → Actual resend/expiry feedback → Change email or return path.

**Primary control and placement:** Verify: below the code field.

**Secondary controls:** Resend is a labelled secondary action only when allowed.

**Color, borders and grouping — why:** Visible input boundary and one primary reduce attention switching; no mandatory six tiny independent boxes or cognitive puzzle.

**Theory and thumb reasoning:** Jakob, Hick and error prevention: familiar labelled fields, staged choice and field recovery. Large lower actions stay above device/navigation/keyboard insets; the lowest screen edge is not assumed universally comfortable.

**Responsive behavior:** At 320–599 units use one column; at 600+ center the form at 560 units maximum. At 200% text stack label/action pairs and let the page scroll above the keyboard.

**Recovery and honesty:** Wrong/expired code is recoverable; retry limits and timers come from the real flow, never a fake countdown.

<a id="e05"></a>
## E05 — Application correction and resubmission

**Purpose:** Respond to reviewer feedback in the current web flow.

**Scope / owner:** external / M03. Existing first-party web flow; native equivalent needs separate API scope.

**Enter / next:** P03, E03 → P03, E04. No operational navigation before fresh authorized entry. Back/recovery/application links retain their real purpose.

**Top region:** Application result and actual feedback.

**Content order:** Pending or rejected status → Allowed corrections and document replacement → Reviewed details that cannot be silently overwritten.

**Primary control and placement:** Submit correction for review: lower action when allowed.

**Secondary controls:** Refresh status and sign out remain distinct.

**Color, borders and grouping — why:** Sand highlights actionable feedback; fields alone have control borders. No green operational badge while placement/review is missing.

**Theory and thumb reasoning:** Jakob, Hick and error prevention: familiar labelled fields, staged choice and field recovery. Large lower actions stay above device/navigation/keyboard insets; the lowest screen edge is not assumed universally comfortable.

**Responsive behavior:** At 320–599 units use one column; at 600+ center the form at 560 units maximum. At 200% text stack label/action pairs and let the page scroll above the keyboard.

**Recovery and honesty:** Feedback is actual; a completed decision cannot be changed through an unsupported field.

<a id="e06"></a>
## E06 — Password recovery request

**Purpose:** Start the supported recovery channel for the registered account.

**Scope / owner:** external / M03. Existing first-party web flow; native equivalent needs separate API scope.

**Enter / next:** P01 → E04, E07, P01. No operational navigation before fresh authorized entry. Back/recovery/application links retain their real purpose.

**Top region:** Recover access and Back.

**Content order:** Persistent email field → Email-code or reset-link option supported by the current flow → Honest sent/request feedback.

**Primary control and placement:** Continue with supported recovery: after email.

**Secondary controls:** Back to Rider sign in; alternate supported recovery path.

**Color, borders and grouping — why:** A simple neutral form avoids decorative distractions; one red continuation makes the action legible.

**Theory and thumb reasoning:** Jakob, Hick and error prevention: familiar labelled fields, staged choice and field recovery. Large lower actions stay above device/navigation/keyboard insets; the lowest screen edge is not assumed universally comfortable.

**Responsive behavior:** At 320–599 units use one column; at 600+ center the form at 560 units maximum. At 200% text stack label/action pairs and let the page scroll above the keyboard.

**Recovery and honesty:** Autofill/paste work; failed delivery of recovery mail is not shown as sent; no unsupported phone/SMS login.

<a id="e07"></a>
## E07 — Recovery: new password

**Purpose:** Set the password after the real verified challenge or reset link.

**Scope / owner:** external / M03. Existing first-party web flow; native equivalent needs separate API scope.

**Enter / next:** E04, E06 → P01, E06. No operational navigation before fresh authorized entry. Back/recovery/application links retain their real purpose.

**Top region:** New password and verified recovery context.

**Content order:** New/confirmation fields with current policy → Show/hide and password manager support → Useful field errors.

**Primary control and placement:** Set password: lower red action.

**Secondary controls:** Back to recovery; success returns to sign in rather than silently creating a native session.

**Color, borders and grouping — why:** Outlined inputs and plain requirements prioritize the task; no made-up password strength or token details in user copy.

**Theory and thumb reasoning:** Jakob, Hick and error prevention: familiar labelled fields, staged choice and field recovery. Large lower actions stay above device/navigation/keyboard insets; the lowest screen edge is not assumed universally comfortable.

**Responsive behavior:** At 320–599 units use one column; at 600+ center the form at 560 units maximum. At 200% text stack label/action pairs and let the page scroll above the keyboard.

**Recovery and honesty:** Expired challenge returns to recovery; success clears secrets; the native app refetches a fresh session after sign-in.

<a id="e08"></a>
## E08 — Email verification outcome

**Purpose:** Read the actual email verification result and return to refresh the account.

**Scope / owner:** external / M03. Existing first-party web flow; native equivalent needs separate API scope.

**Enter / next:** P30 → P30, P01. No operational navigation before fresh authorized entry. Back/recovery/application links retain their real purpose.

**Top region:** Email verification result.

**Content order:** Verified, expired or rejected link result → Actual resend/continuation option → Return-to-Rider instruction.

**Primary control and placement:** Return and refresh verification: supported continuation.

**Secondary controls:** Resend only when available; recovery/help remains secondary.

**Color, borders and grouping — why:** A small confirmed mint state is used only after acceptance; errors use labelled dark error text on a pale inset.

**Theory and thumb reasoning:** Jakob, Hick and error prevention: familiar labelled fields, staged choice and field recovery. Large lower actions stay above device/navigation/keyboard insets; the lowest screen edge is not assumed universally comfortable.

**Responsive behavior:** At 320–599 units use one column; at 600+ center the form at 560 units maximum. At 200% text stack label/action pairs and let the page scroll above the keyboard.

**Recovery and honesty:** Expired link does not become verified; a web result does not automatically transfer browser authentication.

<a id="o01"></a>
## O01 — Go off duty

**Scope / owner / context:** baseline / M05 / P05.

**Visible content and actions:** Explain no new work while existing responsibilities remain; Keep working and Go off duty are explicit.

**Color and border reasoning:** Red only on the chosen confirmation; no destructive account wording.

**Placement / adaptation:** Modal sheet on compact widths with an explicit Close/Cancel path; bounded scroll region and reachable action above the keyboard. At 600+ it can be a centered dialog at 560 units maximum. Scope choices wrap instead of requiring horizontal swipes.

**Interaction reasoning:** Fitts supports large targets; Hick supports focused choices; recognition keeps the related parcel visible. Manage focus, announce errors, handle Back/Escape and restore focus to the opener.

**Recovery:** Pending, rejection and uncertain result keep original duty until confirmed.

<a id="o02"></a>
## O02 — Queue/history filters

**Scope / owner / context:** baseline / M04 / P05.

**Visible content and actions:** Show applicable phase/date/payment filters, Apply and Clear with current selection.

**Color and border reasoning:** Neutral filled choices; rose radio selection; lower Apply reachable.

**Placement / adaptation:** Modal sheet on compact widths with an explicit Close/Cancel path; bounded scroll region and reachable action above the keyboard. At 600+ it can be a centered dialog at 560 units maximum. Scope choices wrap instead of requiring horizontal swipes.

**Interaction reasoning:** Fitts supports large targets; Hick supports focused choices; recognition keeps the related parcel visible. Manage focus, announce errors, handle Back/Escape and restore focus to the opener.

**Recovery:** Cancel restores prior filters; count/result is updated only by the real query.

<a id="o03"></a>
## O03 — Pickup claim review

**Scope / owner / context:** baseline / M06 / P06.

**Visible content and actions:** Review ready parcel, seller, origin hub and returned eligibility before Claim pickup.

**Color and border reasoning:** One red claim; critical facts are neutral; claimed is not collected.

**Placement / adaptation:** Modal sheet on compact widths with an explicit Close/Cancel path; bounded scroll region and reachable action above the keyboard. At 600+ it can be a centered dialog at 560 units maximum. Scope choices wrap instead of requiring horizontal swipes.

**Interaction reasoning:** Fitts supports large targets; Hick supports focused choices; recognition keeps the related parcel visible. Manage focus, announce errors, handle Back/Escape and restore focus to the opener.

**Recovery:** Competing claim/stale capacity retains a useful refresh path.

<a id="o04"></a>
## O04 — Scan match review

**Scope / owner / context:** baseline / M06 / P07.

**Visible content and actions:** Compare actually read and expected full references, then invoke the permitted confirmation.

**Color and border reasoning:** Text and icon accompany a match; wrong code has labelled error.

**Placement / adaptation:** Modal sheet on compact widths with an explicit Close/Cancel path; bounded scroll region and reachable action above the keyboard. At 600+ it can be a centered dialog at 560 units maximum. Scope choices wrap instead of requiring horizontal swipes.

**Interaction reasoning:** Fitts supports large targets; Hick supports focused choices; recognition keeps the related parcel visible. Manage focus, announce errors, handle Back/Escape and restore focus to the opener.

**Recovery:** No automatic stored-code confirmation; duplicate/rejected read keeps custody unchanged.

<a id="o05"></a>
## O05 — Choose parcel compartment

**Scope / owner / context:** selected / M04 / P08.

**Visible content and actions:** Pick a labelled bag/compartment; Save location or Clear for this parcel only.

**Color and border reasoning:** Rose selection plus radio/text and filled 48-unit targets.

**Placement / adaptation:** Modal sheet on compact widths with an explicit Close/Cancel path; bounded scroll region and reachable action above the keyboard. At 600+ it can be a centered dialog at 560 units maximum. Scope choices wrap instead of requiring horizontal swipes.

**Interaction reasoning:** Fitts supports large targets; Hick supports focused choices; recognition keeps the related parcel visible. Manage focus, announce errors, handle Back/Escape and restore focus to the opener.

**Recovery:** Tag save does not prove a scan, physical load or server custody.

<a id="o06"></a>
## O06 — Proof source choice

**Scope / owner / context:** baseline / M07 / P11.

**Visible content and actions:** Offer only supported camera/picker sources with accessible names.

**Color and border reasoning:** Neutral choice rows; no second red submit competes with evidence review.

**Placement / adaptation:** Modal sheet on compact widths with an explicit Close/Cancel path; bounded scroll region and reachable action above the keyboard. At 600+ it can be a centered dialog at 560 units maximum. Scope choices wrap instead of requiring horizontal swipes.

**Interaction reasoning:** Fitts supports large targets; Hick supports focused choices; recognition keeps the related parcel visible. Manage focus, announce errors, handle Back/Escape and restore focus to the opener.

**Recovery:** Unavailable camera shows a supported recovery path, not a fabricated image.

<a id="o07"></a>
## O07 — Replace or remove proof

**Scope / owner / context:** baseline / M07 / P11.

**Visible content and actions:** Preview local selected proof and Replace/Remove before outcome acceptance.

**Color and border reasoning:** Neutral replace; labelled removal; clear local-only meaning.

**Placement / adaptation:** Modal sheet on compact widths with an explicit Close/Cancel path; bounded scroll region and reachable action above the keyboard. At 600+ it can be a centered dialog at 560 units maximum. Scope choices wrap instead of requiring horizontal swipes.

**Interaction reasoning:** Fitts supports large targets; Hick supports focused choices; recognition keeps the related parcel visible. Manage focus, announce errors, handle Back/Escape and restore focus to the opener.

**Recovery:** Accepted immutable proof is viewed in P20 rather than edited here.

<a id="o08"></a>
## O08 — Discard unsaved draft

**Scope / owner / context:** baseline / M16 / caller.

**Visible content and actions:** Keep editing is easy to reach; Discard identifies exactly which local draft is lost.

**Color and border reasoning:** Separated destructive wording; do not color Cancel as the primary outcome.

**Placement / adaptation:** Modal sheet on compact widths with an explicit Close/Cancel path; bounded scroll region and reachable action above the keyboard. At 600+ it can be a centered dialog at 560 units maximum. Scope choices wrap instead of requiring horizontal swipes.

**Interaction reasoning:** Fitts supports large targets; Hick supports focused choices; recognition keeps the related parcel visible. Manage focus, announce errors, handle Back/Escape and restore focus to the opener.

**Recovery:** Dismiss preserves input; discarding does not cancel assignment.

<a id="o09"></a>
## O09 — Sign out

**Scope / owner / context:** baseline / M03 / P29.

**Visible content and actions:** Explain local session exit and safe draft cleanup without surrendering held work.

**Color and border reasoning:** Neutral Cancel and explicit Sign out; no closure wording.

**Placement / adaptation:** Modal sheet on compact widths with an explicit Close/Cancel path; bounded scroll region and reachable action above the keyboard. At 600+ it can be a centered dialog at 560 units maximum. Scope choices wrap instead of requiring horizontal swipes.

**Interaction reasoning:** Fitts supports large targets; Hick supports focused choices; recognition keeps the related parcel visible. Manage focus, announce errors, handle Back/Escape and restore focus to the opener.

**Recovery:** Server revocation failure and local cleanup result are distinct.

<a id="o10"></a>
## O10 — Cash problem guidance

**Scope / owner / context:** baseline / M07 / P12.

**Visible content and actions:** Explain missing amount/insufficient tender/change and open the permitted exception path.

**Color and border reasoning:** Sand guidance with dark amount text; no local override to amount due.

**Placement / adaptation:** Modal sheet on compact widths with an explicit Close/Cancel path; bounded scroll region and reachable action above the keyboard. At 600+ it can be a centered dialog at 560 units maximum. Scope choices wrap instead of requiring horizontal swipes.

**Interaction reasoning:** Fitts supports large targets; Hick supports focused choices; recognition keeps the related parcel visible. Manage focus, announce errors, handle Back/Escape and restore focus to the opener.

**Recovery:** Only supported failure codes and actual evidence can record an outcome.

<a id="o11"></a>
## O11 — Read-only code lookup

**Scope / owner / context:** conditional / M06 / P07.

**Visible content and actions:** Enter/copy a reference to locate owned context when scanning cannot read.

**Color and border reasoning:** Visible text field and neutral Look up; clearly not scan evidence.

**Placement / adaptation:** Modal sheet on compact widths with an explicit Close/Cancel path; bounded scroll region and reachable action above the keyboard. At 600+ it can be a centered dialog at 560 units maximum. Scope choices wrap instead of requiring horizontal swipes.

**Interaction reasoning:** Fitts supports large targets; Hick supports focused choices; recognition keeps the related parcel visible. Manage focus, announce errors, handle Back/Escape and restore focus to the opener.

**Recovery:** Lookup never substitutes for a required genuine matching scan or bypasses camera/evidence policy.

<a id="o12"></a>
## O12 — Call a permitted contact

**Scope / owner / context:** baseline / M09 / P06.

**Visible content and actions:** Show the valid phase contact and let the device dial through explicit action.

**Color and border reasoning:** Neutral labelled Call control, full target and safe dismissal.

**Placement / adaptation:** Modal sheet on compact widths with an explicit Close/Cancel path; bounded scroll region and reachable action above the keyboard. At 600+ it can be a centered dialog at 560 units maximum. Scope choices wrap instead of requiring horizontal swipes.

**Interaction reasoning:** Fitts supports large targets; Hick supports focused choices; recognition keeps the related parcel visible. Manage focus, announce errors, handle Back/Escape and restore focus to the opener.

**Recovery:** Missing phone removes the action; no invented masking/recording service.

<a id="o13"></a>
## O13 — Open navigation

**Scope / owner / context:** baseline / M09 / P10.

**Visible content and actions:** Review saved destination and choose an installed supported navigation app.

**Color and border reasoning:** Opaque white sheet over map; neutral choices and readable address.

**Placement / adaptation:** Modal sheet on compact widths with an explicit Close/Cancel path; bounded scroll region and reachable action above the keyboard. At 600+ it can be a centered dialog at 560 units maximum. Scope choices wrap instead of requiring horizontal swipes.

**Interaction reasoning:** Fitts supports large targets; Hick supports focused choices; recognition keeps the related parcel visible. Manage focus, announce errors, handle Back/Escape and restore focus to the opener.

**Recovery:** Launch failure retains copy/address; no default city or location tracking claim.

<a id="o14"></a>
## O14 — Activity item actions

**Scope / owner / context:** baseline / M12 / P23.

**Visible content and actions:** Open or mark an own event read only where accepted; keep actions contextual.

**Color and border reasoning:** Quiet action rows, labelled selection, no bulk fake success.

**Placement / adaptation:** Modal sheet on compact widths with an explicit Close/Cancel path; bounded scroll region and reachable action above the keyboard. At 600+ it can be a centered dialog at 560 units maximum. Scope choices wrap instead of requiring horizontal swipes.

**Interaction reasoning:** Fitts supports large targets; Hick supports focused choices; recognition keeps the related parcel visible. Manage focus, announce errors, handle Back/Escape and restore focus to the opener.

**Recovery:** Unknown target/read rejection stays readable and does not acknowledge unrelated events.

<a id="o15"></a>
## O15 — Read-status explanation

**Scope / owner / context:** baseline / M10 / P22.

**Visible content and actions:** Explain this thread's displayed acknowledgement and allow a failed read update retry.

**Color and border reasoning:** Neutral explanatory surface; no message-resend button mixed into read retry.

**Placement / adaptation:** Modal sheet on compact widths with an explicit Close/Cancel path; bounded scroll region and reachable action above the keyboard. At 600+ it can be a centered dialog at 560 units maximum. Scope choices wrap instead of requiring horizontal swipes.

**Interaction reasoning:** Fitts supports large targets; Hick supports focused choices; recognition keeps the related parcel visible. Manage focus, announce errors, handle Back/Escape and restore focus to the opener.

**Recovery:** Opening the inbox never marks every thread read.

<a id="o16"></a>
## O16 — Cash and earnings meaning

**Scope / owner / context:** baseline / M15 / P37.

**Visible content and actions:** Explain held, hub-received, reconciled and earned with the returned scope.

**Color and border reasoning:** Neutral labels and small semantic chips; no wallet/withdraw promise.

**Placement / adaptation:** Modal sheet on compact widths with an explicit Close/Cancel path; bounded scroll region and reachable action above the keyboard. At 600+ it can be a centered dialog at 560 units maximum. Scope choices wrap instead of requiring horizontal swipes.

**Interaction reasoning:** Fitts supports large targets; Hick supports focused choices; recognition keeps the related parcel visible. Manage focus, announce errors, handle Back/Escape and restore focus to the opener.

**Recovery:** Unknown finance capability is explicit; no guessed balances.

<a id="o17"></a>
## O17 — Date-range selection

**Scope / owner / context:** baseline / M11 / P18.

**Visible content and actions:** Choose a supported Philippine-date period with Apply/Clear.

**Color and border reasoning:** Readable filled date controls; rose selected range, one primary Apply.

**Placement / adaptation:** Modal sheet on compact widths with an explicit Close/Cancel path; bounded scroll region and reachable action above the keyboard. At 600+ it can be a centered dialog at 560 units maximum. Scope choices wrap instead of requiring horizontal swipes.

**Interaction reasoning:** Fitts supports large targets; Hick supports focused choices; recognition keeps the related parcel visible. Manage focus, announce errors, handle Back/Escape and restore focus to the opener.

**Recovery:** Invalid range is inline; unsupported historical scope is not silently expanded.

<a id="o18"></a>
## O18 — Email verification guidance

**Scope / owner / context:** baseline / M14 / P30.

**Visible content and actions:** Explain the real prerequisite and launch the approved first-party verification path.

**Color and border reasoning:** Neutral information with an explicit continuation, not a fake local verify toggle.

**Placement / adaptation:** Modal sheet on compact widths with an explicit Close/Cancel path; bounded scroll region and reachable action above the keyboard. At 600+ it can be a centered dialog at 560 units maximum. Scope choices wrap instead of requiring horizontal swipes.

**Interaction reasoning:** Fitts supports large targets; Hick supports focused choices; recognition keeps the related parcel visible. Manage focus, announce errors, handle Back/Escape and restore focus to the opener.

**Recovery:** Return refetches actual status; absent verification action is unavailable.

<a id="o19"></a>
## O19 — Choose help parcel context

**Scope / owner / context:** baseline / M14 / P34.

**Visible content and actions:** Choose only returned owned work or Account issue before contacting help.

**Color and border reasoning:** Quiet parcel rows with clear selected radio and reference.

**Placement / adaptation:** Modal sheet on compact widths with an explicit Close/Cancel path; bounded scroll region and reachable action above the keyboard. At 600+ it can be a centered dialog at 560 units maximum. Scope choices wrap instead of requiring horizontal swipes.

**Interaction reasoning:** Fitts supports large targets; Hick supports focused choices; recognition keeps the related parcel visible. Manage focus, announce errors, handle Back/Escape and restore focus to the opener.

**Recovery:** Foreign/expired assignment is excluded; no copying private proof or customer details by default.

<a id="o20"></a>
## O20 — Why this action is unavailable

**Scope / owner / context:** baseline / M04 / caller.

**Visible content and actions:** Explain current missing permission, data, placement or prerequisite and give a real recovery action.

**Color and border reasoning:** Readable neutral/sand message, no decorative disabled-state tooltip requiring hover.

**Placement / adaptation:** Modal sheet on compact widths with an explicit Close/Cancel path; bounded scroll region and reachable action above the keyboard. At 600+ it can be a centered dialog at 560 units maximum. Scope choices wrap instead of requiring horizontal swipes.

**Interaction reasoning:** Fitts supports large targets; Hick supports focused choices; recognition keeps the related parcel visible. Manage focus, announce errors, handle Back/Escape and restore focus to the opener.

**Recovery:** Do not infer a reason from an empty list or promise that a retry will approve the account.

<a id="f01"></a>
## F01 — Future: Shift readiness

**Type / status:** sheet / unselected future concept; not baseline implementation.

**Purpose:** Review actual device readiness and simple rider self-checks before new work.

**Composition and controls:** Hub/duty context, actual camera/connectivity result, cash-change reminder if relevant; lower Continue and Not now.

**Color/borders and theory:** Neutral checklist with one rose selected state; no fake verified equipment or arbitrary mandatory checkboxes. Familiar grouping, readable context and large reachable controls apply.

**Adaptation:** One-column compact layout, accessible lower action, large-text wrapping and measured keyboard/safe-area spacing. Wider views can expose context beside the main work without duplicate primary actions.

**Dependency and recovery:** Optional readiness logic and actual device signals; not selected for implementation. Loading, rejection, denial, missing capability and unconfirmed result must remain separate; no mock success.

<a id="f02"></a>
## F02 — Future: Shift closeout

**Type / status:** full_view / unselected future concept; not baseline implementation.

**Purpose:** See held parcels, pending returns and cash responsibility together after going off duty.

**Composition and controls:** Real period at top, outstanding duties before delivered summary; lower Open next responsibility, with receipts linked in their group.

**Color/borders and theory:** Sand only on unresolved duties; quiet confirmed records. Closing a shift cannot hide custody or imply all cash was received. Familiar grouping, readable context and large reachable controls apply.

**Adaptation:** One-column compact layout, accessible lower action, large-text wrapping and measured keyboard/safe-area spacing. Wider views can expose context beside the main work without duplicate primary actions.

**Dependency and recovery:** Scoped shift data and accepted finance/return resources; not a required duty-blocking gate. Loading, rejection, denial, missing capability and unconfirmed result must remain separate; no mock success.

<a id="f03"></a>
## F03 — Future: Wrong-pin or entrance report

**Type / status:** sheet / unselected future concept; not baseline implementation.

**Purpose:** Report a navigation problem while retaining the original saved destination.

**Composition and controls:** Original address, permitted issue choice and short note; lower Submit report and Cancel; map correction preview only if accepted.

**Color/borders and theory:** Outlined evidence fields and one red Submit; submitted feedback is not an approved destination change. Familiar grouping, readable context and large reachable controls apply.

**Adaptation:** One-column compact layout, accessible lower action, large-text wrapping and measured keyboard/safe-area spacing. Wider views can expose context beside the main work without duplicate primary actions.

**Dependency and recovery:** Accepted report persistence, review ownership and safe destination policy. Loading, rejection, denial, missing capability and unconfirmed result must remain separate; no mock success.

<a id="f04"></a>
## F04 — Future: Arrival estimate and route plan

**Type / status:** full_view / unselected future concept; not baseline implementation.

**Purpose:** Read supported travel estimates and an approved multi-stop sequence.

**Composition and controls:** Estimate range and freshness, route/map/list explanation, accessible stop list and lower Open next stop.

**Color/borders and theory:** Neutral estimate labels distinguish forecast from promise; rose marks current selection; maps never simulate optimized results. Familiar grouping, readable context and large reachable controls apply.

**Adaptation:** One-column compact layout, accessible lower action, large-text wrapping and measured keyboard/safe-area spacing. Wider views can expose context beside the main work without duplicate primary actions.

**Dependency and recovery:** Accepted routing/ETA data, freshness, permission and dispatch policy; current single final-mile capacity remains unchanged. Loading, rejection, denial, missing capability and unconfirmed result must remain separate; no mock success.

<a id="f05"></a>
## F05 — Future: Batch load checklist

**Type / status:** full_view / unselected future concept; not baseline implementation.

**Purpose:** Compare physically read parcel codes with an accepted manifest before departure.

**Composition and controls:** Expected and verified counts, owned parcel list, missing/unexpected discrepancy groups and lower Review load.

**Color/borders and theory:** Text/icon match states and one actionable discrepancy group; scan review precedes any authorized departure. Familiar grouping, readable context and large reachable controls apply.

**Adaptation:** One-column compact layout, accessible lower action, large-text wrapping and measured keyboard/safe-area spacing. Wider views can expose context beside the main work without duplicate primary actions.

**Dependency and recovery:** Accepted batch/manifest/capacity contract and real scan evidence; several final-mile parcels are not currently assignable as a run. Loading, rejection, denial, missing capability and unconfirmed result must remain separate; no mock success.

<a id="f06"></a>
## F06 — Future: Same-stop parcel group

**Type / status:** component / unselected future concept; not baseline implementation.

**Purpose:** Show compatible parcels at one verified collection/delivery stop.

**Composition and controls:** Stop heading and parcel checklist inside Stop Mode; each identifier, cash amount and outcome remains separately visible.

**Color/borders and theory:** A shared region expresses common destination without a bulk Delivered button; grouping must not merge responsibilities. Familiar grouping, readable context and large reachable controls apply.

**Adaptation:** One-column compact layout, accessible lower action, large-text wrapping and measured keyboard/safe-area spacing. Wider views can expose context beside the main work without duplicate primary actions.

**Dependency and recovery:** Verified compatible grouping; final-mile grouping needs separate capacity/assignment acceptance. Loading, rejection, denial, missing capability and unconfirmed result must remain separate; no mock success.

<a id="f07"></a>
## F07 — Future: Queue changed review

**Type / status:** sheet / unselected future concept; not baseline implementation.

**Purpose:** Explain additions, removals or server-directed changes after refresh.

**Composition and controls:** Short change summary, affected parcel references, preserved authorized selection and lower Return to current task.

**Color/borders and theory:** Quiet delta rows and one selected context prevent surprise; no locally optimized reorder is implied. Familiar grouping, readable context and large reachable controls apply.

**Adaptation:** One-column compact layout, accessible lower action, large-text wrapping and measured keyboard/safe-area spacing. Wider views can expose context beside the main work without duplicate primary actions.

**Dependency and recovery:** Reliable comparison of fresh authorized task resources; removed private context is cleared. Loading, rejection, denial, missing capability and unconfirmed result must remain separate; no mock success.

<a id="f08"></a>
## F08 — Future: Recipient PIN verification

**Type / status:** sheet / unselected future concept; not baseline implementation.

**Purpose:** Verify a recipient only if the accepted handoff model requires a real PIN.

**Composition and controls:** Parcel/recipient context, one accessible paste-capable code field, actual expiry/retry feedback and lower Verify.

**Color/borders and theory:** Clear input boundary and single action reduce precision effort; PIN verification does not equal buyer completion. Familiar grouping, readable context and large reachable controls apply.

**Adaptation:** One-column compact layout, accessible lower action, large-text wrapping and measured keyboard/safe-area spacing. Wider views can expose context beside the main work without duplicate primary actions.

**Dependency and recovery:** Backend identity/PIN issuance, verification and failure contract; decorative PIN input is excluded. Loading, rejection, denial, missing capability and unconfirmed result must remain separate; no mock success.

<a id="f09"></a>
## F09 — Future: Shift statement preview

**Type / status:** full_view / unselected future concept; not baseline implementation.

**Purpose:** Review a permitted dated summary before export.

**Composition and controls:** Scope/period and actual trips, returns and receipts; redact unnecessary contacts; lower Export with format disclosure.

**Color/borders and theory:** Neutral document rows and dark amounts encourage verification before sharing; no fabricated payout statement. Familiar grouping, readable context and large reachable controls apply.

**Adaptation:** One-column compact layout, accessible lower action, large-text wrapping and measured keyboard/safe-area spacing. Wider views can expose context beside the main work without duplicate primary actions.

**Dependency and recovery:** Accepted export data/privacy scope and actual file generation; not selected. Loading, rejection, denial, missing capability and unconfirmed result must remain separate; no mock success.

<a id="f10"></a>
## F10 — Future: Editable quick replies

**Type / status:** component / unselected future concept; not baseline implementation.

**Purpose:** Insert a phase-appropriate draft for the rider to review before sending.

**Composition and controls:** Short labelled choices near the composer that insert text, then the existing Send action.

**Color/borders and theory:** Neutral compact chips avoid automatic messages and rival primary buttons; complete instruction remains visible for review. Familiar grouping, readable context and large reachable controls apply.

**Adaptation:** One-column compact layout, accessible lower action, large-text wrapping and measured keyboard/safe-area spacing. Wider views can expose context beside the main work without duplicate primary actions.

**Dependency and recovery:** Optional template/content selection; existing recipient/phase authorization stays in force. Loading, rejection, denial, missing capability and unconfirmed result must remain separate; no mock success.

<a id="f11"></a>
## F11 — Future: Incident report

**Type / status:** sheet / unselected future concept; not baseline implementation.

**Purpose:** Report an incident through a real approved channel if that service is added.

**Composition and controls:** Actual channel/availability, parcel context, permitted issue/evidence, lower Submit or Contact; safety help is clearly labelled.

**Color/borders and theory:** Readable evidence and truthful response state; no invented live monitoring, emergency number or round-the-clock support. Familiar grouping, readable context and large reachable controls apply.

**Adaptation:** One-column compact layout, accessible lower action, large-text wrapping and measured keyboard/safe-area spacing. Wider views can expose context beside the main work without duplicate primary actions.

**Dependency and recovery:** Region-appropriate verified contacts and accepted reporting/support operation. Loading, rejection, denial, missing capability and unconfirmed result must remain separate; no mock success.

<a id="f12"></a>
## F12 — Future: Consented location sharing

**Type / status:** full_view / unselected future concept; not baseline implementation.

**Purpose:** Understand and control location sharing only for an accepted feature.

**Composition and controls:** Who receives location and when, actual permission/share status, explicit Start/Stop and freshness; address still works independently.

**Color/borders and theory:** Control and disclosure precede any moving dot; a permission or toggle is not proof of a live connection. Familiar grouping, readable context and large reachable controls apply.

**Adaptation:** One-column compact layout, accessible lower action, large-text wrapping and measured keyboard/safe-area spacing. Wider views can expose context beside the main work without duplicate primary actions.

**Dependency and recovery:** Explicit location/service/privacy/battery lifecycle scope; no background tracking in the baseline. Loading, rejection, denial, missing capability and unconfirmed result must remain separate; no mock success.
