#!/usr/bin/env python3
"""Validate the Rider planning catalog and render its linked Markdown pages."""

import argparse
from collections import Counter, defaultdict
from datetime import date
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "docs/planning/subtasks.json"


def require(condition, message):
    if not condition:
        raise ValueError(message)


def hours(minutes):
    return f"{minutes / 60:g} h"


def anchor(key):
    return key.lower().replace(".", "-")


def task_link(key, prefix=""):
    return f"[{key}]({prefix}{key.split('.')[0]}.md#{anchor(key)})"


def totals(tasks):
    return (
        sum(t["estimate_minutes"] for t in tasks),
        sum(t["estimate_range_minutes"][0] for t in tasks),
        sum(t["estimate_range_minutes"][1] for t in tasks),
    )


def validate(data):
    require(data["schema_version"] == 1, "Unsupported catalog schema")
    majors = {m["id"]: m for m in data["majors"]}
    require(len(majors) == len(data["majors"]) == 16, "Major areas must be unique")
    require(set(majors) == {f"M{n:02}" for n in range(1, 17)}, "Missing major area")
    gates = {g["id"]: g for g in data["external_gates"]}
    require(len(gates) == len(data["external_gates"]), "Duplicate external gate")
    batches = {b["id"]: b for b in data["batches"]}
    require(len(batches) == len(data["batches"]), "Duplicate batch")
    require(len({b["branch_hint"] for b in batches.values()}) == len(batches),
            "Suggested branch names must be unique")
    tasks = {t["id"]: t for t in data["tasks"]}
    require(len(tasks) == len(data["tasks"]), "Duplicate task ID")
    require(len({t["title"] for t in tasks.values()}) == len(tasks), "Duplicate title")
    members = Counter()
    for batch in batches.values():
        require(batch["major"] in majors, f"Unknown major in {batch['id']}")
        require(1 <= len(batch["task_ids"]) <= 4, f"Oversized batch {batch['id']}")
        require(len(set(batch["task_ids"])) == len(batch["task_ids"]), "Duplicate batch member")
        for key in batch["task_ids"]:
            require(key in tasks, f"Unknown batch member {key}")
            require(tasks[key]["major"] == batch["major"], f"Wrong batch major for {key}")
            require(tasks[key]["batch"] == batch["id"], f"Wrong batch link for {key}")
            members[key] += 1
        require(len({tuple(sorted(tasks[k]["planning_window"].items())) for k in batch["task_ids"]}) == 1,
                f"Batch {batch['id']} spans different milestone windows; split it")
    require(set(members) == set(tasks) and all(n == 1 for n in members.values()),
            "Every subtask must belong to exactly one batch")
    coverage = data["coverage"]
    require(len({r["requirement"] for r in coverage}) == len(coverage),
            "Duplicate coverage requirement")
    for row in coverage:
        require(bool(row["requirement"].strip()) and bool(row["task_ids"]), "Empty coverage row")
        require(set(row["task_ids"]) <= set(tasks), "Unresolved coverage reference")
        require(len(row["task_ids"]) == len(set(row["task_ids"])), "Duplicate coverage reference")
    for major in majors:
        keys = sorted(t["id"] for t in tasks.values() if t["major"] == major)
        require(keys == [f"{major}.{n:02}" for n in range(1, len(keys) + 1)],
                f"Missing or out-of-sequence subtasks in {major}")
        require(bool(keys), f"Empty major {major}")
    for key, task in tasks.items():
        require(task["major"] == key.split(".")[0] and task["major"] in majors,
                f"Invalid major for {key}")
        require(task["title"].startswith(f"rider-mobile/{key} "), f"Invalid title {key}")
        require(bool(task["outcome"].strip()), f"Missing outcome {key}")
        for field, minimum in (("implementation_steps", 3), ("completion_checks", 2)):
            values = task[field]
            require(len(values) >= minimum and all(v.strip() for v in values),
                    f"Incomplete {field} in {key}")
            require(len(values) == len(set(values)), f"Repeated {field} in {key}")
        require(task["work_type"] in {"client", "layout", "decision", "verification", "device", "release"},
                f"Unknown work type {key}")
        require(task["status"] in {"planned", "in_progress", "blocked", "complete"}, f"Invalid status {key}")
        if task["status"] == "complete":
            require(bool(task.get("completion_evidence")), f"Completion needs evidence {key}")
        estimate = task["estimate_minutes"]
        low, high = task["estimate_range_minutes"]
        require(isinstance(estimate, int) and 0 < low <= estimate <= high,
                f"Invalid effort range {key}")
        window = task["planning_window"]
        start, due = (date.fromisoformat(window[f]) for f in ("starts_on", "due_on"))
        require(window["timezone"] == "Asia/Manila", f"Wrong timezone {key}")
        require(1 <= (due - start).days + 1 <= 14, f"Invalid calendar window {key}")
        require(due <= date(2026, 11, 20), f"Past development deadline {key}")
        require(len(task["depends_on"]) == len(set(task["depends_on"])), f"Duplicate dependency {key}")
        for dependency in task["depends_on"]:
            require(dependency in tasks and dependency != key, f"Invalid dependency {key}: {dependency}")
            other = tasks[dependency]["planning_window"]
            require(date.fromisoformat(other["starts_on"]) <= due,
                    f"Dependency window begins too late: {key}, {dependency}")
        require(set(task["external_gates"]) <= set(gates), f"Unknown external gate {key}")
        require(len(task["external_gates"]) == len(set(task["external_gates"])), f"Duplicate external gate {key}")

    def check_graph(edges, name):
        active, visited = set(), set()

        def visit(key):
            require(key not in active, f"Dependency cycle in {name}: {key}")
            if key in visited:
                return
            active.add(key)
            for dependency in edges[key]:
                visit(dependency)
            active.remove(key)
            visited.add(key)

        for key in edges:
            visit(key)

    check_graph({key: task["depends_on"] for key, task in tasks.items()}, "subtasks")
    check_graph({key: sorted({tasks[d]["batch"] for member in batch["task_ids"]
                             for d in tasks[member]["depends_on"] if tasks[d]["batch"] != key})
                 for key, batch in batches.items()}, "suggested batches")
    return majors, gates, batches, tasks


def render(data):
    majors, gates, batches, tasks = validate(data)
    all_tasks = list(tasks.values())
    point, low, high = totals(all_tasks)
    statuses = Counter(t["status"] for t in all_tasks)
    delivery_days = (date(2026, 11, 20) - date(2026, 10, 6)).days + 1
    weekly_hours = point / 60 / (delivery_days / 7)
    index = [
        "# Rider detailed subtask backlog", "",
        f"Reviewed {data['reviewed_on']}. This catalog breaks the **16 major areas into {len(tasks)} subtasks**",
        f"and **{len(batches)} suggested batches**. It is a development plan; creating these docs does",
        "not implement features or create individual future work records.", "",
        f"Current catalog status: **{statuses['planned']} planned, {statuses['in_progress']} in progress,",
        f"{statuses['blocked']} blocked, {statuses['complete']} complete**. Check the [major task map](TASK_TRACKING.md)",
        "and the current code for implementation evidence. IDs such as M02.03 and",
        "B02-B are stable repository references, not external record IDs.", "",
        "## How to select work", "",
        "1. Request one subtask ID or a named batch below. A batch groups one to four",
        "   related subtasks; it is a suggestion, not an instruction to open every branch.",
        "2. Read the selected cards, their direct prerequisites and the prerequisites",
        "   of those prerequisites. Numeric ID order is not dependency order: directions",
        "   is needed before pickup, and the early M16 planning tasks run before release.",
        "3. Re-read the current Bagoo website rules, roadmap, relevant code/tests and",
        "   accepted API/deployment evidence across the affected roles. Follow",
        "   [SOURCES.md](SOURCES.md), [AGENTS.md](../AGENTS.md) and the local work guide.",
        "4. Implement only the requested scope. Report missing prerequisites; do not",
        "   silently add their implementation to the request. A layout card may use",
        "   explicitly labelled development fixtures where its scope allows them.",
        "   Fixture evidence never clears an operational API or hardware prerequisite.",
        "5. Before activation, choose a realistic 1–14 inclusive calendar-day window",
        "   ending no later than November 20, with honest effort and satisfied dependencies.",
        "   Create or reuse only the requested execution record; keep actual time measured.",
        "6. Verify the card's checks and relevant cross-feature rules, save meaningful",
        "   local commits, and report remaining limits. The user handles every push.",
        "   Update catalog status and evidence only for work actually verified.", "",
        "### Example later prompts", "",
        "> Work on M01.01 only. Read its backlog card and current website sources,",
        "> record the reviewed revision and dependencies, verify its checks, and commit locally.", "",
        "> Implement B02-B: M02.03, M02.04 and M02.05. Check prerequisites and current",
        "> website changes first. Keep unavailable operational features gated, verify",
        "> the selected scope, and make meaningful local commits. I will push.", "",
        "These are prompt examples for later work. They do not begin implementation now.", "",
        "## Effort and calendar limits", "",
        f"The detailed client estimate is **{hours(point)}**, with a **{hours(low)}–{hours(high)} planning range**.",
        "It covers the same baseline plus explicit integration, failure, privacy, device",
        "and acceptance work; it excludes backend implementation and this",
        "documentation effort. The earlier 130–204-hour coarse estimate is superseded",
        "for future client planning, not an additional budget. See",
        "[DELIVERY_PLAN.md](DELIVERY_PLAN.md) for the target and required scope decisions.", "",
        data["estimate_basis"], "",
        "Ranges are rounded per card to half-hour planning units around provisional",
        "point estimates. They are not logged time, statistical confidence intervals",
        "or a promise that all backend decisions will resolve inside them.", "",
        data["schedule_policy"], "",
        f"The full point estimate requires about {weekly_hours:.0f} client hours per week across",
        "October 6–November 20, before backend effort. Several original milestone",
        "windows are overloaded for one maintainer; the table below exposes that",
        "problem rather than promising that all cards fit. Replan sequence/capacity",
        "or agree a narrower honest demonstration. Preserve custody, authorization,",
        "evidence, idempotency and money safeguards in any selected operational slice.", "",
        "| Original reference | Tentative window, 2026 | Days | Detailed client effort | Hours per calendar day |",
        "|---|---|---:|---:|---:|",
    ]
    by_window = defaultdict(list)
    for task in all_tasks:
        w = task["planning_window"]
        by_window[(w["milestone"], w["starts_on"], w["due_on"])].append(task)
    for (milestone, start, due), members in sorted(by_window.items()):
        days = (date.fromisoformat(due) - date.fromisoformat(start)).days + 1
        effort = totals(members)[0]
        index.append(f"| {milestone} | {start} → {due} | {days} | {hours(effort)} | {effort / 60 / days:.1f} |")
    index += ["", "M16.01 belongs to early R01 planning and M16.02 to R03 interruption policy;",
              "their inclusion here avoids postponing all reliability work until the end.",
              "R11 contains rehearsal only. Shared windows require prerequisite ordering",
              "inside them; they do not authorize concurrent unfinished dependencies.", "",
              "## Major-area index", "",
              "Every card has an outcome, implementation steps, explicit completion checks,",
              "direct dependencies, external prerequisites, effort, a tentative milestone",
              "window and a suggested batch. All completion checkboxes start unchecked.", "",
              "| Area | Detailed cards | Subtasks | Batches | Point effort | Planning range |",
              "|---|---|---:|---:|---:|---|" ]
    pages = {}
    for key, major in majors.items():
        members = [t for t in all_tasks if t["major"] == key]
        own_batches = [b for b in batches.values() if b["major"] == key]
        p, lo, hi = totals(members)
        index.append(f"| {key} | [{major['name']}](backlog/{key}.md) | {len(members)} | {len(own_batches)} | {hours(p)} | {hours(lo)}–{hours(hi)} |")
        lines = [f"# {key} — {major['name']}", "",
                 "[Backlog index](../SUBTASK_BACKLOG.md) · [Major task map](../TASK_TRACKING.md)", "",
                 f"**{len(members)} subtasks · {len(own_batches)} suggested batches · {hours(p)} point effort · {hours(lo)}–{hours(hi)} range.**", "",
                 "This is planned Rider client work. Follow the selection, evidence and",
                 "calendar rules in the index. Branch names are suggestions; prerequisites",
                 "and actual capacity determine when any branch can start. Current website",
                 "rules and backend implementation evidence must be checked again.", "",
                 "## Suggested batches", ""]
        for batch in own_batches:
            batch_tasks = [tasks[k] for k in batch["task_ids"]]
            bp, bl, bh = totals(batch_tasks)
            outside = sorted({d for t in batch_tasks for d in t["depends_on"] if d not in batch["task_ids"]})
            external = sorted({g for t in batch_tasks for g in t["external_gates"]})
            lines += [f'<a id="{anchor(batch["id"])}"></a>', "",
                      f"### {batch['id']} — {batch['name']}", "",
                      f"- Subtasks: {', '.join(task_link(k) for k in batch['task_ids'])}.",
                      f"- Suggested branch: `{batch['branch_hint']}`.",
                      f"- Client effort: **{hours(bp)}**, range {hours(bl)}–{hours(bh)}.",
                      "- Direct prerequisites outside this batch: " + (", ".join(task_link(k) for k in outside) or "none") + ".",
                      "- External prerequisites: " + (", ".join(f"[{g}](../SUBTASK_BACKLOG.md#gate-{g.lower()})" for g in external) or "no operational API gate; current source/decision review still applies") + ".", ""]
        lines += ["## Subtask cards", ""]
        for task in members:
            w = task["planning_window"]
            days = (date.fromisoformat(w["due_on"]) - date.fromisoformat(w["starts_on"])).days + 1
            lo, hi = task["estimate_range_minutes"]
            title = task["title"].split(" ", 1)[1]
            lines += [f'<a id="{anchor(task["id"])}"></a>', "",
                      f"### {task['id']} — {title}", "",
                      f"**Title:** `{task['title']}`", "",
                      f"**Outcome:** {task['outcome']}", "",
                      f"- Status: **{task['status']}**; work type: {task['work_type']}.",
                      f"- Client effort: **{hours(task['estimate_minutes'])}**, range {hours(lo)}–{hours(hi)}.",
                      f"- Tentative milestone reference: {w['milestone']}, {w['starts_on']} → {w['due_on']} ({days} calendar days; Asia/Manila). Replan before activation.",
                      f"- Suggested batch: [{task['batch']}](#{anchor(task['batch'])}).",
                      "- Prerequisite subtasks: " + (", ".join(task_link(k) for k in task["depends_on"]) or "none; begin with current source review") + ".",
                      "- External prerequisites: " + (", ".join(f"[{g}](../SUBTASK_BACKLOG.md#gate-{g.lower()})" for g in task["external_gates"]) or "none beyond the card's source/decision requirements") + ".", "",
                      "Implementation steps:", ""]
            lines += [f"{n}. {step}" for n, step in enumerate(task["implementation_steps"], 1)]
            lines += ["", "Completion checks:", ""]
            mark = "x" if task["status"] == "complete" else " "
            lines += [f"- [{mark}] {check}" for check in task["completion_checks"]]
            if task.get("completion_evidence"):
                lines += ["", "Recorded completion evidence:", ""]
                lines += [f"- {e}" for e in task["completion_evidence"]]
            lines.append("")
        lines += ["Generated from [the catalog](../planning/subtasks.json). Edit that source",
                  "and run `python tool/render_rider_backlog.py` from the repository root.", ""]
        pages[ROOT / f"docs/backlog/{key}.md"] = "\n".join(lines)
    index += ["", "## Requirement coverage", "",
              "Use this map alongside the major-area screen map and the acceptance matrix.",
              "The references identify planned implementation or checks; they are not",
              "evidence that a requirement currently passes. Each selected slice also",
              "inherits the shared authority, privacy and honest-state rules.", "",
              "| Requirement | Planned implementation or acceptance cards |",
              "|---|---|"]
    for row in data["coverage"]:
        index.append(f"| {row['requirement']} | {', '.join(task_link(k, 'backlog/') for k in row['task_ids'])} |")
    index += ["", "## External prerequisite register", "",
              "These entries define required evidence, not a declaration that the backend",
              "is ready. Check the relevant current implementation/contract/device record",
              "for each selected card; accepted paper payloads do not satisfy live gates.",
              "Backend implementation stays with its owner and its current roadmap.", ""]
    for gate in gates.values():
        index += [f'<a id="gate-{gate["id"].lower()}"></a>', "",
                  f"### {gate['id']}", "", gate["requirement"], "",
                  "Catalog state: requires current evidence. Record the accepted source/API",
                  "revision and relevant passing checks before operational integration.", ""]
    index += ["## Keeping the backlog current", "",
              "The canonical editable source is [planning/subtasks.json](planning/subtasks.json).",
              "The index and sixteen area pages are generated views. Keep existing IDs stable;",
              "add new bounded cards instead of renumbering old references. Split or replan",
              "a selected batch if current scope, API changes or capacity make it too large.", "",
              "```sh", "python tool/render_rider_backlog.py", "python tool/render_rider_backlog.py --check", "```", "",
              "Validation checks unique/sequential IDs, area coverage, batch ownership,",
              "resolved requirement references, acyclic task and batch dependencies,",
              "evidence for completed cards,",
              "effort ranges, timezone, calendar limits and generated-page consistency.",
              "It does not prove live API, deployed website or physical-device readiness.", "",
              "Feature checks are incremental acceptance for each implemented slice.",
              "M16 checks whole-app integration, device/process behavior and release evidence;",
              "they do not replace those incremental checks or double-count their execution.", "",
              "When a selected slice finishes, attach real evidence to its catalog status,",
              "update the major map's remaining work and affected flow/API/readiness docs,",
              "and keep backend acceptance evidence in the owning project. Major areas stay",
              "unfinished until their required cards and area-level acceptance are verified.", ""]
    pages[ROOT / "docs/SUBTASK_BACKLOG.md"] = "\n".join(index)
    return pages


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Validate without changing generated files")
    args = parser.parse_args()
    data = json.loads(CATALOG.read_text())
    pages = render(data)
    stale = []
    for path, content in pages.items():
        if args.check:
            if not path.exists() or path.read_text() != content:
                stale.append(str(path.relative_to(ROOT)))
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content)
    require(not stale, "Generated pages need regeneration: " + ", ".join(stale))
    print(f"Verified {len(data['tasks'])} subtasks, {len(data['batches'])} batches and {len(pages)} pages.")


if __name__ == "__main__":
    main()
