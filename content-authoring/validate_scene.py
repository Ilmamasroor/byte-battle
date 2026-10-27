#!/usr/bin/env python3
"""Validate scene JSON files against SCENE_SCHEMA.md. Usage: validate_scene.py <file-or-dir> [...]"""
import json, sys, os, re, glob

KINDS = {"computer", "structure", "table", "sequence", "flow"}
STATES = {"idle", "cur", "compare", "swap", "done", "found", "dim", "bad", "", "free", "used", "hot", "todo", "active"}
STRUCT = {"array", "list", "stack", "queue", "hash", "tree", "graph", "gantt", "bars"}
HIGHLIGHT = {"cpu", "ram", "stack", "heap", "disk", "net", "console"}
ICONS = set("search code check timer chat people storage speed warning flag star loop lock bolt build school list compare help cloud lightbulb".split())
UUID = re.compile(r"^00000000-0000-0000-0000-0000000010(0[1-9]|[1-5][0-9])$")

def err(errs, msg): errs.append(msg)

def check_states(errs, where, items, key="s"):
    for i, it in enumerate(items or []):
        if isinstance(it, dict) and it.get(key, "") not in STATES:
            err(errs, f"{where}[{i}] bad state {it.get(key)!r}")

def validate(doc, name):
    errs = []
    cid = doc.get("conceptId", "")
    if not UUID.match(cid): err(errs, f"conceptId invalid: {cid!r}")
    if name and os.path.basename(name) != f"{cid}.json": err(errs, f"file name must be <conceptId>.json (got {os.path.basename(name)})")
    kind = doc.get("kind")
    if kind not in KINDS: err(errs, f"kind must be one of {sorted(KINDS)}"); return errs
    for k, lim in (("title", 90), ("intro", 170), ("takeaway", 170)):
        v = doc.get(k, "")
        if not v: err(errs, f"{k} missing")
        elif len(v) > lim: err(errs, f"{k} too long ({len(v)}>{lim})")
    p = doc.get("predict")
    if p is not None:
        if not (3 <= len(p.get("options", [])) <= 4): err(errs, "predict.options must have 3-4 entries")
        elif not (0 <= p.get("answer", -1) < len(p["options"])): err(errs, "predict.answer out of range")
        if not p.get("question") or not p.get("reveal"): err(errs, "predict needs question and reveal")
        if len(p.get("reveal", "")) > 230: err(errs, "predict.reveal too long")
    code = doc.get("code")
    if code is not None:
        if not (isinstance(code, list) and 1 <= len(code) <= 14): err(errs, "code must be a list of 1-14 lines")
        elif any(len(l) > 48 for l in code): err(errs, "code line > 48 chars")
    steps = doc.get("steps", [])
    if not (7 <= len(steps) <= 12): err(errs, f"need 7-12 steps, has {len(steps)}")
    merged = {}
    actors = None
    for i, s in enumerate(steps):
        w = f"step {i + 1}"
        say = s.get("say", "")
        if not say: err(errs, f"{w}: say missing")
        elif len(say) > 180: err(errs, f"{w}: say too long ({len(say)}>180)")
        if re.search(r"[—–]|\*\*|`", say): err(errs, f"{w}: no em dashes / markdown in say")
        for k in list(merged):
            if k in ("msg", "msgs"): merged.pop(k)
        merged.update({k: v for k, v in s.items() if k not in ("say", "note")})
        at = merged.get("at")
        if code is not None and at is not None:
            for a in (at if isinstance(at, list) else [at]):
                if not (isinstance(a, int) and -1 <= a < len(code)): err(errs, f"{w}: at={a!r} outside code")
        if kind == "computer":
            for h in merged.get("highlight", []):
                if h not in HIGHLIGHT and not h.startswith("panel:"): err(errs, f"{w}: bad highlight {h!r}")
            for fr in merged.get("stack", []):
                if "frame" not in fr: err(errs, f"{w}: stack frame needs 'frame'")
            for ob in merged.get("heap", []):
                if not {"id", "type"} <= set(ob): err(errs, f"{w}: heap object needs id,type")
            cpu = merged.get("cpu", {})
            if "cores" in cpu and not (1 <= len(cpu["cores"]) <= 4): err(errs, f"{w}: cores 1-4")
            if not any(k in merged for k in ("cpu", "stack", "heap", "grid", "panels", "disk", "net", "console", "code")): err(errs, f"{w}: nothing to show")
            check_states(errs, f"{w}: grid.cells", (merged.get("grid") or {}).get("cells"))
        elif kind == "structure":
            sts = merged.get("structures", [])
            if not sts: err(errs, f"{w}: structures missing")
            for j, b in enumerate(sts):
                bk = b.get("kind")
                if bk not in STRUCT: err(errs, f"{w}: structure[{j}] bad kind {bk!r}"); continue
                if bk == "array":
                    if not 1 <= len(b.get("cells", [])) <= 10: err(errs, f"{w}: array needs 1-10 cells")
                    check_states(errs, f"{w}: array.cells", b.get("cells"))
                if bk == "list": check_states(errs, f"{w}: list.nodes", b.get("nodes"))
                if bk in ("stack", "queue"): check_states(errs, f"{w}: {bk}.items", b.get("items"))
                if bk == "hash":
                    for bu in b.get("buckets", []): check_states(errs, f"{w}: hash.items", bu.get("items"))
                if bk == "tree":
                    ids = {n.get("id") for n in b.get("nodes", [])}
                    if not ids: err(errs, f"{w}: tree needs nodes")
                    for n in b.get("nodes", []):
                        for c in ("l", "r"):
                            if n.get(c) and n[c] not in ids: err(errs, f"{w}: tree child {n[c]!r} not a node id")
                    check_states(errs, f"{w}: tree.nodes", b.get("nodes"))
                if bk == "graph":
                    ids = {n.get("id") for n in b.get("nodes", [])}
                    if not 2 <= len(ids) <= 8: err(errs, f"{w}: graph needs 2-8 nodes")
                    for n in b.get("nodes", []):
                        if not (0 <= n.get("x", -1) <= 1 and 0 <= n.get("y", -1) <= 1): err(errs, f"{w}: graph node x,y must be 0..1")
                    for e in b.get("edges", []):
                        if e.get("a") not in ids or e.get("b") not in ids: err(errs, f"{w}: edge refers to unknown node {e}")
                    check_states(errs, f"{w}: graph.nodes", b.get("nodes")); check_states(errs, f"{w}: graph.edges", b.get("edges"))
                if bk == "gantt":
                    if not b.get("max"): err(errs, f"{w}: gantt needs max")
                    for ln in b.get("lanes", []):
                        for bl in ln.get("blocks", []):
                            if bl.get("start", 0) + bl.get("len", 0) > b.get("max", 0) + 1e-9: err(errs, f"{w}: gantt block beyond max")
                if bk == "bars":
                    for br in b.get("bars", []):
                        if not 0 <= br.get("value", -1) <= 1: err(errs, f"{w}: bar value 0..1")
        elif kind == "table":
            if not merged.get("tables") and not merged.get("result"): err(errs, f"{w}: tables or result needed")
            for t in merged.get("tables", []):
                if len(t.get("rows", [])) > 7: err(errs, f"{w}: table > 7 rows")
                for r in t.get("rows", []):
                    if len(r) != len(t.get("cols", [])): err(errs, f"{w}: row width != cols in {t.get('name')}")
        elif kind == "sequence":
            if i == 0: actors = merged.get("actors")
            actors = merged.get("actors") or actors
            if not actors or not 2 <= len(actors) <= 4: err(errs, f"{w}: need 2-4 actors"); continue
            m = s.get("msg")
            if m:
                if not (0 <= m.get("from", -1) < len(actors) and 0 <= m.get("to", -1) < len(actors)): err(errs, f"{w}: msg from/to out of range")
                if len(m.get("label", "")) > 28: err(errs, f"{w}: msg label too long")
                if m.get("kind") not in (None, "req", "res", "note", "error"): err(errs, f"{w}: bad msg kind")
            elif i > 0 and not s.get("msgs"): err(errs, f"{w}: sequence step should carry a msg")
        elif kind == "flow":
            cards = merged.get("cards", [])
            if not 3 <= len(cards) <= 5: err(errs, f"{w}: 3-5 cards")
            for c in cards:
                if c.get("icon") and c["icon"] not in ICONS: err(errs, f"{w}: bad icon {c['icon']!r}")
                if c.get("s") not in ("todo", "active", "done"): err(errs, f"{w}: card state todo/active/done")
    return errs

def main(paths):
    files = []
    for p in paths:
        files += sorted(glob.glob(os.path.join(p, "*.json"))) if os.path.isdir(p) else [p]
    bad = 0
    for f in files:
        try: doc = json.load(open(f))
        except Exception as e: print(f"FAIL {f}: not valid JSON ({e})"); bad += 1; continue
        errs = validate(doc, f)
        if errs:
            bad += 1; print(f"FAIL {os.path.basename(f)}"); [print("   -", e) for e in errs]
        else: print(f"ok   {os.path.basename(f)}  ({doc['kind']}, {len(doc['steps'])} steps)")
    print(f"\n{len(files) - bad}/{len(files)} valid")
    return 1 if bad else 0

if __name__ == "__main__":
    sys.exit(main(sys.argv[1:] or ["."]))
