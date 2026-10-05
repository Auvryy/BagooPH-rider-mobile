# Working in BagooPH Rider Mobile

## Before starting work

1. Read this file and [docs/README.md](docs/README.md).
2. Read the local **Task Creator.md** at the repository root before handling
   each work request. It defines how to create or reuse a work record, choose
   a realistic deadline, track measured time, and verify updates.
3. Inspect the branch, worktree, relevant code, and applicable documentation.
   Preserve unrelated changes and establish what is implemented versus planned.
4. Read [docs/TASK_TRACKING.md](docs/TASK_TRACKING.md) to identify the major work
   area, screens, dependencies and finish evidence before planning feature slices.
   Always reference the current Bagoo website project to keep track of its docs,
   new features and behavior across buyer, seller, courier, logistics and admin.
   Before each branch, inspect relevant current web rules, roadmap, code and
   tests; record the reviewed revision and the accepted API/deployment evidence.
   Use [docs/SOURCES.md](docs/SOURCES.md) for authority and conflict handling.
5. Reuse an existing record when a prompt continues the same task. Create a
   record for new feature, fix, branch, documentation, or investigation work.
   A conversational question alone does not need a new development task.
6. Start every mobile task title with the exact `rider-mobile/` prefix, followed
   by a clear description, such as `rider-mobile/validate pickup waybills`.
   Before any task write, re-read its current title and require that prefix.
   This applies to edits, status/dates, checklists, comments, timers/time logs,
   dependencies, attachments and deletion. Preserve the prefix when renaming.
   Refer to web/shared tasks without editing them; a Rider label, parent or
   matching keyword alone does not establish mobile ownership.

An explicitly requested rename of a verified existing Rider Mobile task may
add the prefix once. Preserve its other fields and verify the new title before
any further writes. This exception does not authorize renaming unrelated tasks.

The local guide is intentionally ignored by Git and is supplied separately on
each machine. If it is missing or its tracker is unavailable, report the gap,
continue independent authorized work, and preserve an accurate local account
of what remains to be recorded. Do not claim tracking succeeded. Do not invent
service names, credentials, CLI paths, or remote task IDs.

## Scope and ownership

- This repository contains the rider Flutter app. Pickup and final-mile work
  belong to one `courier` role. Buyer, seller, hub, and admin screens belong
  to their own applications.
- The Bagoo web/backend repository is a reference. Do not modify it unless the
  user explicitly includes backend changes in the task. Coordinate API work
  through [docs/api/INTEGRATION_PLAN.md](docs/api/INTEGRATION_PLAN.md).
- Follow the source authority and conflict rules in
  [docs/SOURCES.md](docs/SOURCES.md). Never copy historical shortcuts into a
  live rider action. Keep the latest backend audit in the backend repository.
- The presentation target is November 21, 2026, Asia/Manila. November 20 is the
  latest development deadline. Read [docs/DELIVERY_PLAN.md](docs/DELIVERY_PLAN.md)
  before changing scope or delivery commitments.

## Implementation rules

- Keep server-owned approval, assignment, capacity, custody, prices, COD,
  timestamps, retries, and earnings out of client authority.
- Off duty blocks new work; existing authorized responsibilities remain.
  Suspension requires an explicit recovery capability and hub recovery.
- Preserve mandatory Mother-Hub routing, hub-owned intake, buyer-only
  completion, and separate COD collection, remittance, and reconciliation.
- Use the documented feature structure, repository interfaces, and shared
  transport. Widgets do not call HTTP or implement business transitions.
- All API routes in these docs are proposals until backend implementation and
  contract tests confirm them. Unsupported actions remain unavailable.
- Keep fake repositories and scanner input in explicit development/test
  configurations. A production feature cannot report fixture success.
- Match the rider design: accent `#E00D42`, canvas `#FFFAFB`, 8 logical-pixel
  corners, labelled touch controls, accessible text, and safe-area spacing.
  Bundle the selected typeface when its implementation task starts.
- Add dependencies when their feature needs them. Check current primary
  documentation, platform support, license, and SDK compatibility first.

## Privacy and Git

- Never publish the local guide, its contents, work-tracker identity, URLs,
  machine paths, task IDs, session details, or receipts in public files,
  branches, commits, or pull requests. Use generic wording in public docs.
- Verify `git check-ignore "Task Creator.md"` and check the staged diff before
  creating a commit. Never force-add the guide or assume ignore rules protect
  an already tracked file. The user supplies private onboarding separately.
- Keep credentials, signing material, tokens, KYC, and proof files out of Git
  and logs. Compile-time configuration is public configuration, not a secret.
- Stage and commit completed, verified work locally on each task branch by
  default. The user has authorized local commits; do not ask again for routine
  staging or committing within the requested scope.
- Break each branch into focused, meaningful commits that group related changes
  by purpose. Keep code and the docs/tests needed to understand that change
  together. Simple work may need one commit; do not split files arbitrarily or
  mix unrelated features just to reach a commit count.
- Use clear imperative commit messages describing the resulting change, with
  a useful type/scope when appropriate, such as `docs: define rider custody flow`
  or `feat(auth): add courier sign-in`. Avoid vague messages like “update” or
  “changes”; add a body when rationale or limitations need explanation.
- Stage explicit task files or hunks, inspect the staged diff for scope/privacy,
  run relevant checks, and commit each coherent milestone. Preserve unrelated
  user changes. Do not leave completed authorized work uncommitted without
  explaining a specific blocker.
- The user always handles pushing. Never run `git push`, auto-publish commits,
  or enable a tool/hook that pushes on the user's behalf. Report the local
  branch, commit summaries and relevant checks so the user can review and push.
- Do not amend, rebase, squash or rewrite existing commits unless explicitly
  requested. Make a new focused correction commit when needed.
- Never discard unrelated work or edit another project's working branch.

## Verification and reporting

- Run checks appropriate to the change. Docs need link, consistency, privacy,
  and diff checks. Runtime features need meaningful controller/widget/contract
  checks; Android camera and lifecycle behavior need a physical phone.
- Report exact checks performed and material limits. Desktop Device Preview
  verifies layouts, not native permissions, scanning, or Android performance.
- Update relevant docs when behavior changes. Keep planned interfaces labelled
  and do not mark unfinished backend dependencies complete.
- Keep major-area coverage and remaining work current in `docs/TASK_TRACKING.md`
  after each feature slice. Create later subtasks only when requested; a major
  area is not a single oversized branch or a duplicate backend progress list.
- Follow the local guide for concise progress notes and completion evidence.
  Log measured time only. Estimates are never substituted for actual time.
- Confirm an effort estimate before active work and use a timer for every work
  session. Stop it when pausing, switching tasks or finishing; verify that the
  session was recorded once and the timer is stopped.
- Before marking a task done, inspect its time entries and logged-versus-estimated
  summary. Report the measured total and explain meaningful variance through
  Rider work performed. Never randomize, pad or rewrite actual time for appearance
  or to match an estimate. Revise future estimates when scope or evidence changes.
- Task titles, descriptions, checklists, comments and time-entry notes describe
  only BagooPH Rider work, its outcomes and actual checks. Keep local tools,
  automation, services, configuration paths and guide contents out of remote
  task text. Related backend details belong there only when needed to explain
  a Rider feature or integration dependency.
