#!/usr/bin/env python3
"""Validate and render the planned Rider design inventory and page blueprints."""
from pathlib import Path
from collections import Counter
import argparse,json,re

ROOT=Path(__file__).resolve().parents[1]
DESIGN=ROOT/'docs/design'

FAMILIES={
 'form':('Jakob, Hick and error prevention: familiar labelled fields, staged choice and field recovery.','At 320–599 units use one column; at 600+ center the form at 560 units maximum. At 200% text stack label/action pairs and let the page scroll above the keyboard.'),
 'holding':('Feedback and recognition: visible exact status and responsible actor avoid guessing what is pending.','Keep one readable status column on phones; center to 640 units on wider windows. Long feedback wraps; receiving instructions remain above any action.'),
 'list':('Grouping, Hick and recognition: stable categories and labelled rows reduce searching and repeated memory.','One list column on compact widths. At 960+ use a 300-unit list with detail only when the remaining detail pane is at least 420 units; preserve selection through reflow.'),
 'stop':('Hick, grouping, distinctiveness and thumb reach: one permitted action with the parcel, address and evidence context.','Compact stack keeps address and action before optional map detail. At 960+ put map beside the task with 420+ units for task content; collapse back to one stack at large text.'),
 'scan':('Fitts and feedback: large controls outside the viewfinder and explicit actual-code review.','Fit the camera to available width/height; landscape keeps opaque controls beside it without covering the scan guide. Large text can reduce camera area, never the labels.'),
 'finder':('Recognition, grouping and thumb reach: a labelled spatial aid supplements full parcel identity.','Diagram and selected parcel stack on phones; a wide window places parcel list beside the diagram. Slots retain 48-unit targets and text labels; no drag-only assignment.'),
 'guide':('Grouping, progressive disclosure and recognition: readable instructions before optional detail.','Reading column is at most 680 units and wraps at 320. Wide windows can show a contents rail; keyboard focus and large text preserve reading order.'),
 'map':('Grouping, Fitts and error prevention: opaque controls, an equivalent stop list/address and explicit directions.','Map uses remaining bounded space without swallowing the address. Compact controls occupy an opaque lower/side group; low-height landscape and large text favor the textual stop view.'),
 'finance':('Recognition and error prevention: clear amount meanings and labelled review precede any accepted financial action.','Currency and labels stay together on phones; two columns are allowed only for independent groups on wide windows. At 200% text put amount underneath its label.'),
 'receipt':('Feedback and distinctiveness: the confirmed outcome is specific and the next action is calm.','One centered receipt column on compact and wide windows, 680-unit maximum. Extra detail can expand below, while the recorded status stays near the heading.'),
 'timeline':('Grouping and recognition: connected actual events communicate sequence without inventing progress.','Timeline is vertical on phones and stays vertical on wide windows. Optional detail opens alongside at 960+; long reasons and dates wrap without truncation.'),
 'media':('Fitts and feedback: accessible media controls and a safe return path accompany gestures.','Image letterboxes within available space; opaque labelled controls remain reachable in portrait/landscape and at large text. The viewer is a temporary full-screen focus flow.'),
 'chat':('Jakob, grouping and feedback: familiar conversation structure, stable parcel context and explicit Send.','Compact shows one pane; composer moves above the keyboard and the temporary focus view covers bottom navigation. Wide layout uses list/detail when enough width remains, preserving draft and scroll.'),
 'profile':('Recognition and grouping: real identity and managed records are separated from editable contact actions.','Compact stacks identity and settings rows; wide uses a modest identity column and details. Avatar/cover stays small when text increases; private fields do not become decorative cards.'),
 'detail':('Recognition, grouping and progressive disclosure: key facts and one relevant action precede secondary records.','Compact uses labelled definition rows and readable wrapping. Wide can pair a related panel with the main column, never stretching a form or duplicating the action.'),
 'choice':('Hick, Fitts and feedback: a small set of real choices, large targets and a preview of the consequence.','Options stack at 320 and 200% text. Wider layouts may put a sample beside the options; radio labels retain 48-unit touch regions.')
}
SHELLS={
 'root':'Persistent Tasks / Trips / Messages / Profile navigation. Actions are not tabs. Native medium/wide uses a rail when geometry permits.',
 'child':'Parent tab stays selected; compact read/detail views keep the tab bar. Back returns to the actual origin with selection/scroll preserved.',
 'focus':'Temporary full-screen workflow covers the tab bar. Back/Close and parcel context stay visible; exiting restores the originating tab and safe draft state.',
 'auth':'No operational navigation before fresh authorized entry. Back/recovery/application links retain their real purpose.',
 'holding':'No ordinary work tabs while access is restricted. Show only actual allowed refresh, correction, recovery, help and sign-out paths.'
}

def require(ok,msg):
 if not ok:raise ValueError(msg)

def validate(d):
 require(d['schema_version']==1,'Unsupported design schema')
 sections=['pages','external_views','overlays','system_surfaces','states','stop_variants','future_concepts']
 ids=[x['id'] for sec in sections for x in d[sec]]
 require(len(ids)==len(set(ids)),'Duplicate design ID')
 all_ids=set(ids);special={'start','root','caller'}
 require(len(d['pages'])==48 and len(d['external_views'])==8 and len(d['overlays'])==20,'Scope counts changed; review the counted design promise')
 require([x['id'] for x in d['pages']]==[f'P{i:02}' for i in range(1,49)],'Missing full view')
 require([x['label'] for x in d['root_navigation']]==['Tasks','Trips','Messages','Profile'],'Primary navigation changed')
 for p in d['pages']+d['external_views']:
  for key in ['name','purpose','top','primary','secondary','why','special_states','dependency']:
   require(isinstance(p[key],str) and len(p[key].strip())>(2 if key=='name' else 10),f"Incomplete {key}: {p['id']}")
  require(len(p['blocks'])>=2,f"Missing content stack: {p['id']}")
  require(p['shell'] in SHELLS and p['family'] in FAMILIES,f"Missing pattern: {p['id']}")
  require(p['scope'] in {'baseline','selected','conditional','optional','external'},'Unknown scope')
  require(p['native_implemented'] is False,'Design cannot claim runtime implementation')
  require(set(p['entry']+p['children'])<=all_ids|special,f"Unresolved navigation: {p['id']}")
 require({p['name'] for p in d['pages'] if p['scope']=='selected'}=={'Stop Mode','Parcel Finder','Doorstep Guide'},'Selected feature mismatch')
 for o in d['overlays']:require(o['parent'] in all_ids|special and not o['native_implemented'],'Invalid overlay')
 require({r['area'] for r in d['coverage']}=={f'M{i:02}' for i in range(1,17)},'Missing major-area design coverage')
 for r in d['coverage']+d['idea_coverage']:require(set(r['surfaces'])<=all_ids,'Missing coverage surface')
 require([r['idea'] for r in d['idea_coverage']]==list(range(1,41)),'An earlier research idea is missing')
 baseline=json.loads((ROOT/'docs/planning/subtasks.json').read_text())
 require(len(baseline['tasks'])==180,'Baseline task count changed')
 return d

def link(i):
 return f'[{i}](PAGE_BLUEPRINTS.md#{i.lower()})'
def render(d):
 scopes=Counter(x['scope'] for x in d['pages'])
 lines=['# Rider screen inventory','',f"Reviewed {d['reviewed_on']}. This is a counted design proposal, not a native route implementation.",'',
 '## What counts as a page','',
 'A full view has a distinct task and designed composition. Reusable Stop Mode stages, filters, tabs, system prompts and error states are counted separately. A full-screen form step may share one implementation route with another step. Counts describe design coverage, not a mandated number of route files.','',
 f"- **48 native full views:** {scopes['baseline']} baseline, {scopes['selected']} selected feature views, {scopes['conditional']} conditional and {scopes['optional']} optional.",
 '- **8 external views/panels:** existing first-party application/recovery steps; these are not eight new native screens or necessarily eight web URLs.',
 '- **20 app overlays**, **3 device-owned surfaces**, **15 shared states** and **8 Stop Mode stage variants**.',
 '- **12 unselected future concepts:** 5 full views, 5 sheets and 2 components. If all five future full views were later chosen, the theoretical native full-view pool would be **53**. That is not current implementation scope.',
 '- Current native operational screen implementation remains absent from the starter. The existing 180-card baseline is unchanged.','',
 '## Primary navigation','',
 '| Destination | Full view | Role |','|---|---|---|']
 for x in d['root_navigation']:lines.append(f"| {x['label']} | {link(x['page'])} | Stable top-level destination; never a duty or submit action |")
 lines+=['','## Full native views','','| ID | Page | Scope | Parent/context |','|---|---|---|---|']
 for p in d['pages']:lines.append(f"| {link(p['id'])} | {p['name']} | {p['scope']} | {', '.join(p['entry'])} |")
 lines+=['','## External application and recovery','','| ID | View/panel | Purpose |','|---|---|---|']
 for p in d['external_views']:lines.append(f"| {link(p['id'])} | {p['name']} | {p['purpose']} |")
 lines+=['','## App overlays','','| ID | Overlay | Owning context | Scope |','|---|---|---|---|']
 for o in d['overlays']:lines.append(f"| {link(o['id'])} | {o['name']} | {o['parent']} | {o['scope']} |")
 for title,sec,key in [('Device-owned surfaces','system_surfaces','purpose'),('Shared states','states','behavior')]:
  lines+=['',f'## {title}','','| ID | Name | Visible behavior |','|---|---|---|']
  for x in d[sec]:lines.append(f"| {x['id']} | {x['name']} | {x[key]} |")
 lines+=['','## Stop Mode variants','','| ID | Stage | Authorized stop | Primary interaction | Truth |','|---|---|---|---|---|']
 for x in d['stop_variants']:lines.append(f"| {x['id']} | {x['name']} | {x['stop']} | {x['primary']} | {x['truth']} |")
 lines+=['','## Unselected future concepts','','| ID | Concept | Type |','|---|---|---|']
 for x in d['future_concepts']:lines.append(f"| {link(x['id'])} | {x['name']} | {x['kind']} |")
 lines+=['','## Coverage of every major work area','','| Area | Designed surfaces | Why included |','|---|---|---|']
 for x in d['coverage']:lines.append(f"| {x['area']} | {', '.join(x['surfaces'])} | {x['reason']} |")
 lines+=['','## Coverage of the earlier 40 ideas','','Every earlier idea resolves to a specified page, state or explicitly future concept. This mapping does not select all those ideas for implementation.','',
 '| Research idea | Designed surface IDs |','|---|---|']
 for x in d['idea_coverage']:lines.append(f"| {x['idea']:02} | {', '.join(x['surfaces'])} |")
 lines+=['','The canonical design data is [screens.json](screens.json). Validate and regenerate with the design rendering tool. Navigation IDs are planning references, not backend endpoints.','']
 blue=['# Rider page blueprints','',
 'These are frontend specifications for all counted views. Read [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md) and [RESEARCH_AND_RATIONALE.md](RESEARCH_AND_RATIONALE.md) for shared tokens and limits of the theories. Every data page uses the applicable shared states in [SCREEN_INVENTORY.md](SCREEN_INVENTORY.md#shared-states); the specific recovery rule below adds its own context.','',
 'Entry/next IDs describe intended navigation, not actual deployed routes. A temporary focus workflow restores its parent, and Back never transfers a draft or command to another parcel.','']
 for p in d['pages']+d['external_views']:
  theory,adaptive=FAMILIES[p['family']]
  blue += [f"<a id=\"{p['id'].lower()}\"></a>",f"## {p['id']} — {p['name']}",'',
   f"**Purpose:** {p['purpose']}",'',
   f"**Scope / owner:** {p['scope']} / {p['owner']}. {p['dependency']}",'',
   f"**Enter / next:** {', '.join(p['entry'])} → {', '.join(p['children'])}. {SHELLS[p['shell']]}",'',
   f"**Top region:** {p['top']}",'',
   '**Content order:** '+' → '.join(p['blocks'])+'.','',
   f"**Primary control and placement:** {p['primary']}",'',
   f"**Secondary controls:** {p['secondary']}",'',
   f"**Color, borders and grouping — why:** {p['why']}",'',
   f"**Theory and thumb reasoning:** {theory} Large lower actions stay above device/navigation/keyboard insets; the lowest screen edge is not assumed universally comfortable.",'',
   f"**Responsive behavior:** {adaptive}",'',
   f"**Recovery and honesty:** {p['special_states']}",'']
 for o in d['overlays']:
  blue += [f"<a id=\"{o['id'].lower()}\"></a>",f"## {o['id']} — {o['name']}",'',
    f"**Scope / owner / context:** {o['scope']} / {o['owner']} / {o['parent']}.",'',
    f"**Visible content and actions:** {o['content']}",'',
    f"**Color and border reasoning:** {o['treatment']}",'',
    '**Placement / adaptation:** Modal sheet on compact widths with an explicit Close/Cancel path; bounded scroll region and reachable action above the keyboard. At 600+ it can be a centered dialog at 560 units maximum. Scope choices wrap instead of requiring horizontal swipes.','',
    '**Interaction reasoning:** Fitts supports large targets; Hick supports focused choices; recognition keeps the related parcel visible. Manage focus, announce errors, handle Back/Escape and restore focus to the opener.','',
    f"**Recovery:** {o['recovery']}",'']
 for x in d['future_concepts']:
  blue += [f"<a id=\"{x['id'].lower()}\"></a>",f"## {x['id']} — Future: {x['name']}",'',
   f"**Type / status:** {x['kind']} / unselected future concept; not baseline implementation.",'',
   f"**Purpose:** {x['purpose']}",'',f"**Composition and controls:** {x['layout']}",'',
   f"**Color/borders and theory:** {x['why']} Familiar grouping, readable context and large reachable controls apply.",'',
   '**Adaptation:** One-column compact layout, accessible lower action, large-text wrapping and measured keyboard/safe-area spacing. Wider views can expose context beside the main work without duplicate primary actions.','',
   f"**Dependency and recovery:** {x['dependency']} Loading, rejection, denial, missing capability and unconfirmed result must remain separate; no mock success.",'']
 return {DESIGN/'SCREEN_INVENTORY.md':'\n'.join(lines),DESIGN/'PAGE_BLUEPRINTS.md':'\n'.join(blue)}

def main():
 parser=argparse.ArgumentParser(description=__doc__)
 parser.add_argument('--check',action='store_true')
 args=parser.parse_args()
 d=validate(json.loads((DESIGN/'screens.json').read_text()))
 output=render(d);stale=[]
 for p,text in output.items():
  if args.check:
   if not p.exists() or p.read_text()!=text:stale.append(str(p.relative_to(ROOT)))
  else:p.write_text(text,encoding='utf-8')
 require(not stale,'Generated docs are stale: '+', '.join(stale))
 print('Verified 48 full native views, 8 external views, 20 overlays, 3 system surfaces, 15 states, 8 Stop Mode variants, 12 future concepts, 16 areas and all 40 idea mappings.')
if __name__=='__main__':main()
