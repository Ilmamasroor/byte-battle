# Scene schema ("see it happen" animations)

Every concept gets ONE scene file: `frontend/assets/scenes/<conceptId>.json` (full concept UUID, e.g.
`00000000-0000-0000-0000-000000001001.json`). A scene is a short, narrated animation of 7 to 12 steps that lets a
learner WATCH the idea happen. Bit (the app's friendly companion) says one `say` line per step while a stage shows it.

Goal: after the scene a beginner can explain the concept to a friend. Think "inside the computer" and "show, don't tell".

## Document

```json
{
  "conceptId": "00000000-0000-0000-0000-000000001001",
  "title": "Inside your computer: running int x = 5",
  "kind": "computer | structure | table | sequence | flow",
  "intro": "One friendly sentence from Bit that sets up the prediction (<= 160 chars).",
  "predict": { "question": "...?", "options": ["A", "B", "C"], "answer": 1, "reveal": "Why the answer is B (<= 200 chars)." },
  "takeaway": "The one sentence to remember (<= 160 chars).",
  "steps": [ { "say": "Narration (<= 170 chars, plain words, second person), ...stage state... } ]
}
```
* `predict` is optional but strongly recommended (a guess before watching makes learning stick). 3 or 4 options.
* `steps`: 7 to 12. Each has `say` (required) and optional `note` (a short monospace caption such as `visited = {A, B}`).
* STATE INHERITS: any top-level state key a step omits keeps its value from the previous step. Provide a key again
  to replace it entirely (not merge). So step 1 sets up everything; later steps list only what changes.
* Exception: `msg` / `msgs` (sequence kind) are per-step events and are NOT inherited.
* Text rules: no markdown, no emojis, no em dashes. Plain ASCII quotes. Keep every label short (cells <= 8 chars).
* Use the same vocabulary the concept's lessons use. Technically correct beats cute; cute is fine when correct.

## Cell / node / edge states (`s`)
`idle` (default) · `cur` (being worked on) · `compare` (being examined) · `swap` (changing) · `done` (settled) ·
`found` (the answer) · `dim` (ignored/discarded) · `bad` (error / conflict).

## kind = "computer"  (the signature "inside your computer" view)
Optional keys (all inherit):
* CODE: put the program ONCE at document level as `"code": ["int x = 5;", "..."]` (<= 14 lines, each <= 48 chars) and set
  `"at": 0` (0-based line executing now, or a list; -1 = none) on any step that moves it (`at` inherits).
  Works for `computer` AND `structure` scenes, so a learner sees the source line and the machine react together.
* `cpu`: `{ "doing": "execute: int x = 5", "regs": { "PC": "line 1", "x": "5" }, "cores": ["T1", null, "T2", null] }`
  (`cores` = one entry per core, null = idle; use it for scheduling/threads. `regs` values are strings.)
* `stack`: `[ { "frame": "main()", "vars": { "x": "5", "c": "-> obj1" } } ]` bottom frame first. A value starting with
  "->" is drawn as a reference.
* `heap`: `[ { "id": "obj1", "type": "Counter", "fields": { "value": "0" }, "state": "new | live | garbage" } ]`
* `grid`: `{ "title": "Physical memory (frames)", "cells": [ { "label": "P1:0", "s": "used | free | hot | bad" } ] }`
* `panels`: `[ { "title": "Page table (P1)", "rows": [["page","frame"],["0","3"]], "hl": [1] } ]` generic tables
  (page tables, ready queues, process control blocks, file tables). `hl` = highlighted row indexes.
* `disk`: `["notes.txt", "game.exe"]`        * `net`: `{ "label": "Network card", "packets": ["SYN ->"] }`
* `console`: `["Hello", "5"]` program output so far.
* `highlight`: which parts glow this step: any of `"cpu" "ram" "stack" "heap" "disk" "net" "console" "panel:0"`.
* `flow`: `[["cpu","ram"]]` animate data moving between two parts (use `cpu`+`ram`).
Use `computer` for: language/runtime concepts, memory, objects, exceptions, OS (processes, threads, scheduling,
paging, mutex), anything where "what is the machine doing" is the best explanation.

## kind = "structure"  (data structures and algorithms)
`structures`: list of blocks shown top to bottom; each is `{ "kind": ..., "name": "nums", "caption": "optional" , ...}`
* `array`: `cells: [{"v":"5","s":"idle"}]`, `pointers: {"lo":0,"mid":3,"hi":6}` (labels drawn under that index)
* `list`: `nodes: [{"v":"3","s":"idle"}]`, optional `head: "head"`, `doubly: true`, `cycle: true`
* `stack`: `items: [...]` bottom first.     * `queue`: `items: [...]` front first.
* `hash`: `buckets: [{"i":0,"items":[{"v":"Ann:9","s":"idle"}]}]` (items = chain, left to right)
* `tree`: `nodes: [{"id":"a","v":"8","l":"b","r":"c","s":"idle"}]` FIRST node is the root; `l`/`r` are child ids.
* `graph`: `nodes: [{"id":"A","x":0.1,"y":0.5,"s":"idle","note":"d=0"}]` (x,y in 0..1), `edges: [{"a":"A","b":"B","w":"4","s":"idle"}]`,
  optional `directed: true`.
* `gantt`: `lanes: [{"name":"CPU","blocks":[{"label":"P1","start":0,"len":4,"s":"cur"}]}]`, `max: 12`, `time: 5`
* `bars`: `bars: [{"label":"O(n)","value":0.4,"text":"40 ops","s":"compare"}]` (value 0..1), for comparing costs.
Also allowed: document-level `code` + step `at` (see computer) to show the source above the animation.
A step can show several structures at once (e.g. BFS: graph + queue + visited array).

## kind = "table"  (SQL and relational ideas)
* `query`: `{ "text": "SELECT name FROM users WHERE age > 18", "focus": "WHERE" }` (focus clause is highlighted)
* `tables`: `[ { "name": "users", "cols": ["id","name","age"], "rows": [["1","Ann","17"]], "hl": [0], "dim": [1], "hlCols": [2] } ]`
* `result`: `{ "cols": [...], "rows": [[...]], "hl": [0] }` the result table, building up as steps advance.
Keep tables to <= 6 rows, <= 4 columns.

## kind = "sequence"  (protocols, systems, transactions: who talks to whom)
* `actors`: `["Browser","DNS server","Web server"]` (2 to 4; set in step 1, inherited)
* `actorState`: `{ "0": "idle", "2": "LISTEN" }` (keys are actor indexes as strings; replaces whole map)
* `msg`: `{ "from": 0, "to": 1, "label": "who is example.com?", "kind": "req | res | note | error" }`
  ONE message per step; messages accumulate on screen. `note` kind draws a callout at `from` (use `from == to`).
  Labels <= 24 chars.

## kind = "flow"  (interview strategy / frameworks / checklists)
* `cards`: `[ { "icon": "search", "title": "Clarify", "text": "Ask about input size.", "s": "todo | active | done" } ]`
  icons: search code check timer chat people storage speed warning flag star loop lock bolt build school list compare help cloud lightbulb
  Provide the FULL list of cards every step (3 to 5 cards); advance `s` as the story progresses.

## Quality bar (a reviewer will check these)
1. 7 to 12 steps; each step teaches exactly one thing; the last step lands the takeaway.
2. Values are correct at every step (re-trace your own example by hand!). Sorting/search/graph states must match the real algorithm.
3. The scene fits a phone width (390px): <= 8 array cells, <= 7 graph nodes, <= 6 table rows, short labels.
4. `predict` (when present) is a real, interesting question whose answer the animation reveals.
5. Narration is warm and concrete, never "as we can see". No jargon without a one-line plain explanation on first use.
