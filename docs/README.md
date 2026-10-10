# Rider documentation map

Reviewed October 7, 2026. Working presentation target: **November 21, 2026**,
Asia/Manila. Latest development deadline: **November 20**.

BagooPH Rider Mobile is the dedicated Android client for approved pickup and
final-mile couriers. The Laravel application owns all operational decisions.
These documents adapt the web project's rider contracts to a native application;
they do not authorize changing the backend or implementing every proposed feature.

## Read in this order

| Document | Question it answers |
|---|---|
| [PRODUCT_SCOPE.md](PRODUCT_SCOPE.md) | Who uses this app, what belongs in the presentation, and what stays outside? |
| [FEATURE_DIRECTION.md](FEATURE_DIRECTION.md) | Which selected frontend features do we want, how will they work, and how do pickup claims differ from final-mile assignment? |
| [DESIGN_SPEC.md](DESIGN_SPEC.md) | How should every page, overlay, map and state look and behave, with responsive navigation, visual rules and research rationale? |
| [AUTH_PREVIEW.md](AUTH_PREVIEW.md) | How can I open and review the implemented login and registration design previews? |
| [ACCOUNT_ACCESS.md](ACCOUNT_ACCESS.md) | How do real Laravel login, verified registration, authenticated home and logout work locally? |
| [HOME_PREVIEW.md](HOME_PREVIEW.md) | Which historical Home fixtures remain covered by automated layout tests? |
| [RIDER_PAGES.md](RIDER_PAGES.md) | How do Home/Tasks, Trips, Messages and Profile-to-Settings work, with honest live-data availability and an isolated full-page preview? |
| [SETTINGS.md](SETTINGS.md) | How are profile contact, password and additional-email forms prepared, and which backend/live checks remain? |
| [SETTINGS_UX.md](SETTINGS_UX.md) | How does the compact mobile Settings hierarchy reduce scrolling and preserve readable actions? |
| [MOBILE_STYLE_IMPLEMENTATION.md](MOBILE_STYLE_IMPLEMENTATION.md) | Which new visual tokens now style existing app screens, with what verification limits? |
| [AZURE_ACCOUNT_ACCESS.md](AZURE_ACCOUNT_ACCESS.md) | How do I run the native app against the deployed HTTPS account API, and which live/device checks passed? |
| [TASK_TRACKING.md](TASK_TRACKING.md) | What are the 16 major work areas, which screens belong to them, and how will later tasks/branches build and verify them? |
| [SUBTASK_BACKLOG.md](SUBTASK_BACKLOG.md) | Which of the 180 detailed cards or 63 suggested batches can a later prompt select, with what dependencies, steps, checks and effort? |
| [Plan registry](plans/README.md) | Where do separate implementation plans live, with their own files and ownership? |
| [Native operations plan](plans/native-operations/README.md) | How will the completed backend handoff be integrated in five selected Flutter batches? |
| [RIDER_FLOW.md](RIDER_FLOW.md) | What may a rider do at each stage, including failures and cash custody? |
| [TECH_STACK.md](TECH_STACK.md) | Which tools are installed, which are proposed, and why choose them? |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Where does Flutter code belong and how does data reach the screens? |
| [api/CONTRACT.md](api/CONTRACT.md) | What JSON, commands, errors, authentication, and retry behavior should both repos agree on? |
| [api/INTEGRATION_PLAN.md](api/INTEGRATION_PLAN.md) | How do backend and mobile changes progress together without duplicating rules? |
| [DELIVERY_PLAN.md](DELIVERY_PLAN.md) | What can fit before November 21, and which prerequisites can block it? |
| [VERIFICATION_AND_READINESS.md](VERIFICATION_AND_READINESS.md) | What proves readiness, and how do the before/after documentation ratings compare? |
| [DECISIONS_AND_IDEAS.md](DECISIONS_AND_IDEAS.md) | Which choices are recommended, open, or deliberately deferred? |
| [SOURCES.md](SOURCES.md) | Which web contracts and official technical references support the plan? |

## Mobile visual direction

The current design documents define an independent modern mobile presentation:
neutral `#F7F7FA`, borderless filled controls, continuous inset groups, system type, frosted floating
chrome, spring feedback and
primary red `#E00D42`. The website supplies business rules and shared branding;
its CSS/layout does not govern mobile screens. Core visual tokens now apply to
existing runtime screens; the wider design inventory remains planned. See [the design specification](DESIGN_SPEC.md).

## Current code versus target

The app contains connected login, verified three-stage registration, an approved-account
workspace and approval holding/logout, bundled
Bagoo branding and Plus Jakarta Sans, Android/Linux/web runners and an optional
layout frame. Ordinary native runs connect directly to Azure. [Account access](ACCOUNT_ACCESS.md) records the implementation, local
backend contract and checks. The [selected Home refinement](plans/home-dashboard-navigation/HOME_POLISH.md) connects v1 Home and queues and improves map/task interaction. Operational-write acceptance, parcel outcomes and later connected-record batches remain separate.
The account endpoints are available on Azure HTTPS, and native Android login,
secure-session restoration and logout have passed. See the
[deployment acceptance record](AZURE_ACCOUNT_ACCESS.md) for signup evidence and
remaining website/device checks. The wider API and feature architecture remain
proposals beyond this slice.

The earlier [Home fixtures](HOME_PREVIEW.md) and workspace examples now run only
inside automated tests. The app has no Demo login or Preview Rider pages route.
Ordinary APKs and Linux runs use real Azure account access. Live operational
queues and custody actions remain separate work.

The [Rider page slice](RIDER_PAGES.md) adds Tasks/Trips/Messages/Profile navigation,
nested Settings, real own-account information and truthful unavailable states
for undeployed native resources. Sample checks do not establish live integration.

At the earlier backend main revision `4e3a66d`, `routes/api.php` exposed public
tracking only. The web maintainer subsequently integrated the account adapter
into main `0132562` and reported deploying it to Azure. HTTPS checks now confirm
the account routes; parcel-operation APIs remain separate work.
The backend's [current roadmap](https://github.com/Auvryy/BagooPH/blob/main/docs/CORE_FLOW_ROADMAP.md)
owns changing implementation evidence; [the integration plan](api/INTEGRATION_PLAN.md)
records the dated observations needed to start this client.

**October 9 handoff:** backend native operations are now present in clean main
`1d785aa`, with an executable operations specification. Flutter still selects its
unavailable operations repository. The [isolated five-batch plan](plans/native-operations/README.md)
records the source, deployment/session gate and client acceptance. Azure rollout
and actual Android operational behavior remain unverified by this planning task.

Settings API source is merged into backend main `1dba047`; subsequent native/live
checks and remaining private/device acceptance are recorded in
[account settings](SETTINGS.md). Preserve that consumer during operations work;
the new handoff does not complete deferred password/email acceptance.

Use three distinct labels in future reviews: **implemented and verified**,
**implemented but awaiting verification**, and **proposed or blocked**. A screen,
package, or endpoint name in a document is not implementation evidence.

## Authority and updates

Web contracts govern commercial states, approval, physical custody, money, and
actor permissions. This repo governs Flutter presentation, client structure,
and its agreed API consumer contract. Read [SOURCES.md](SOURCES.md) to resolve
conflicts. Record the conflict and coordinate the owning backend change;
never weaken a business rule to make a mobile demonstration work.

Always reference the current Bagoo website project before a Rider feature branch:
check its docs, new features, roadmap, relevant code and tests across all roles.
Record the source/API revision and verify deployed cross-role behavior when the
slice is integrated. Use [TASK_TRACKING.md](TASK_TRACKING.md) for mobile work
ownership and [SUBTASK_BACKLOG.md](SUBTASK_BACKLOG.md) for requested bounded work.
Detailed future cards stay in this repository; only requested execution slices
become active work records. Check prerequisites and replan tentative dates using
the detailed effort; keep changing backend evidence in the web roadmap.

Update the flow, contract, acceptance cases, and delivery dependencies together
when an approved feature changes. Keep examples synthetic and avoid copying
the web roadmap's running status lists into role guides.
