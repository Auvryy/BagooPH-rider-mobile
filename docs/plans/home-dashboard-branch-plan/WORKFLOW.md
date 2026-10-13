# One branch, one implementation prompt, one review cycle

The technical branch documents are the source of selected scope. Do not start all
HDB branches from the planning prompt. Copyable AI prompts are supplied separately;
they are kept outside Git under the repository's privacy/prompt rules.

## Current planning delivery

This documentation branch is `docs/home-dashboard-branch-plan`, created from
mobile `main` at `e04a253`. It adds the review, blueprint, branch briefs and API
checklist. It fixes no runtime bug and activates no production write. Review and
merge this plan before selecting HDB-01.

## Repeat this cycle

1. Choose one HDB ID whose prerequisites and external evidence are available.
   Read its brief, review, API checklist, current AGENTS/local guide and the current
   backend code/docs read only. Record source changes rather than trusting an old
   snapshot. Re-estimate this slice and its 1–14-day window by November 20.
2. Inspect the mobile branch/worktree. Start from clean, updated `main` after the
   preceding required branch is merged. Preserve unrelated work; an existing
   unfinished branch is continued or isolated, not reset or silently rewritten.
3. Create only the selected named branch and one appropriately scoped work record.
   Implement its runtime change and meaningful checks, then update its own evidence
   and brief status. Do not activate transitive prerequisite implementation merely
   because a gate is missing.
4. Review the concrete result: behavior, diff, analysis/tests, any ordinary native
   build needed, and real API/phone evidence when required. Local commits group
   coherent verified changes. Missing live/device evidence stays visibly open.
5. The user pushes that branch, opens/reviews the PR and merges it into `main`.
   The agent never pushes. Pushing alone does not put those commits into `main`.
6. Switch to `main`, pull the merged result, verify a clean expected state, then
   create the next selected branch and issue the next implementation prompt.
   Fixes requested during review stay on the current branch until it is finished.

## Concrete first transition

Run these as the user when the planning branch is reviewed:

```bash
git push -u origin docs/home-dashboard-branch-plan
```

Open and merge its PR. After that merge, in the Rider Mobile checkout:

```bash
git status --short
git switch main
git pull --ff-only origin main
git switch -c fix/home-read-recovery
```

Select HDB-01 for implementation. Do not run the transition through uncommitted
unrelated work. If a named branch already exists, inspect and continue it instead
of recreating or force-resetting it.

After HDB-01 passes review, the user's publication command is:

```bash
git push -u origin fix/home-read-recovery
```

Merge that PR before pulling `main` and creating `fix/home-navigation-lifecycle`
for HDB-02. Repeat using the next actual branch name in [BRANCHES.md](BRANCHES.md).
No rebase, force push or history rewrite is part of this ordinary cycle.

## What each future prompt must specify

- The selected HDB ID and brief, and that only this slice is activated.
- The current mobile checkout/branch and the expected prerequisite merges.
- Website code/docs are read only unless the user explicitly changes that scope.
- Required source/API/deployment/phone gates and the exact behavior to verify.
- What may change, what remains with another OPS/role owner, and which state must
  remain unavailable when a gate is absent.
- Analysis and meaningful checks, evidence updates, local commits and user-only
  publication. No credentials, provider keys or real private data in Git/logs.

For an absent gate, complete useful authorized preparation and a precise handoff
without claiming the gated outcome. Do not convert a fixture, typed scan, guessed
hub or an APK into live operational acceptance.

## Keep the two repositories separate

Mobile publication/merge changes Flutter source; it does not deploy the Laravel
API to Azure. Backend publication, migrations and rollout remain the website
owner's work. A Flutter branch never pulls, switches, edits or deploys the Bagoo
checkout just to make its checks pass.

Rebuild an APK after runtime/configuration changes before installing it. The
ignored Geoapify configuration remains local; it is not published with the branch.
Linux Device Preview is a layout frame, not physical Android scanning/GPS evidence.

## Finish report for each branch

State the concrete resulting behavior, exact checks and material limits; list
local commits and remaining API/device blockers. Update only verified evidence,
not every major-area/backlog status. A branch can finish its selected local work
while a distinct external acceptance gate remains open, but must not call the
full gated feature accepted.
