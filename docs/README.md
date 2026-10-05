# Rider documentation map

Reviewed October 5, 2026. Working presentation target: **November 21, 2026**,
Asia/Manila. Latest development deadline: **November 20**.

BagooPH Rider Mobile is the dedicated Android client for approved pickup and
final-mile couriers. The Laravel application owns all operational decisions.
These documents adapt the web project's rider contracts to a native application;
they do not authorize changing the backend or implementing every proposed feature.

## Read in this order

| Document | Question it answers |
|---|---|
| [PRODUCT_SCOPE.md](PRODUCT_SCOPE.md) | Who uses this app, what belongs in the presentation, and what stays outside? |
| [TASK_TRACKING.md](TASK_TRACKING.md) | What are the 16 major work areas, which screens belong to them, and how will later tasks/branches build and verify them? |
| [SUBTASK_BACKLOG.md](SUBTASK_BACKLOG.md) | Which of the 180 detailed cards or 63 suggested batches can a later prompt select, with what dependencies, steps, checks and effort? |
| [RIDER_FLOW.md](RIDER_FLOW.md) | What may a rider do at each stage, including failures and cash custody? |
| [TECH_STACK.md](TECH_STACK.md) | Which tools are installed, which are proposed, and why choose them? |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Where does Flutter code belong and how does data reach the screens? |
| [api/CONTRACT.md](api/CONTRACT.md) | What JSON, commands, errors, authentication, and retry behavior should both repos agree on? |
| [api/INTEGRATION_PLAN.md](api/INTEGRATION_PLAN.md) | How do backend and mobile changes progress together without duplicating rules? |
| [DELIVERY_PLAN.md](DELIVERY_PLAN.md) | What can fit before November 21, and which prerequisites can block it? |
| [VERIFICATION_AND_READINESS.md](VERIFICATION_AND_READINESS.md) | What proves readiness, and how do the before/after documentation ratings compare? |
| [DECISIONS_AND_IDEAS.md](DECISIONS_AND_IDEAS.md) | Which choices are recommended, open, or deliberately deferred? |
| [SOURCES.md](SOURCES.md) | Which web contracts and official technical references support the plan? |

## Current code versus target

The committed starter contains a welcome screen, Android/Linux/web runners,
Flutter dependencies, and debug Device Preview. It has no authentication,
repositories, rider screens, operational fixture data, or backend connection.
The architecture and `/api/v1` routes described here are **proposed**.

The reviewed backend has reusable courier/lifecycle services and existing web
operations. Its `routes/api.php` exposes public tracking only. Installing Sanctum
as a Composer dependency does not mean mobile token authentication is configured.
The backend's [current roadmap](https://github.com/Auvryy/BagooPH/blob/main/docs/CORE_FLOW_ROADMAP.md)
owns changing implementation evidence; [the integration plan](api/INTEGRATION_PLAN.md)
records the dated observations needed to start this client.

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
