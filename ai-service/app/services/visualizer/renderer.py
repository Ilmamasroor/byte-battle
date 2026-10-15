"""Pure-Python SVG swimlane renderer. Self-contained (draws its own background)
so it reads on light and dark pages. All text is XML-escaped."""
from typing import Any, Dict, List, Optional
from xml.sax.saxutils import escape, quoteattr

from app.services.visualizer.models import VisModel

BG = "#f8fafc"
INK = "#0f172a"
MUTED = "#475569"
GRID = "#cbd5e1"
HAZARD = "#dc2626"
FONT = "font-family=\"ui-monospace, SFMono-Regular, Menlo, Consolas, monospace\""

KIND_STYLE = {
    "READ": ("#dbeafe", "#2563eb"),
    "WRITE": ("#ffedd5", "#ea580c"),
    "LOCK": ("#ede9fe", "#7c3aed"),
    "UNLOCK": ("#f3e8ff", "#9333ea"),
    "WAIT": ("#ccfbf1", "#0d9488"),
    "NOTIFY": ("#ccfbf1", "#0f766e"),
    "SLEEP": ("#e2e8f0", "#64748b"),
    "START": ("#e2e8f0", "#334155"),
    "JOIN": ("#e2e8f0", "#334155"),
}

LANE_W = 230
BOX_W = 200
BOX_H = 38
ROW_H = 52
TOP = 96
LEFT = 54
RIBBON_W = 112


def _t(x: float, y: float, text: str, size: int = 12, weight: str = "normal", fill: str = INK, anchor: str = "start") -> str:
    return (
        f'<text x="{x:.1f}" y="{y:.1f}" font-size="{size}" font-weight="{weight}" fill="{fill}" '
        f'text-anchor="{anchor}" {FONT}>{escape(str(text))}</text>'
    )


def _trunc(s: str, n: int) -> str:
    s = " ".join(str(s).split())
    return s if len(s) <= n else s[: n - 1] + "…"


def _title(kind: str) -> str:
    return {
        "SAFE": "Safe schedule (sequentially consistent)",
        "RACE": "Race condition: lost update interleaving",
        "DEADLOCK": "Deadlock: circular lock wait",
    }.get(kind, kind)


def render_schedule(model: VisModel, schedule: Dict[str, Any], hazards: Optional[List[Dict[str, Any]]] = None) -> str:
    steps: List[Dict[str, Any]] = schedule.get("steps", [])
    threads_used: List[str] = []
    for s in steps:
        if s["thread"] not in threads_used:
            threads_used.append(s["thread"])
    # keep model order
    order = [t.id for t in model.threads if t.id in threads_used]
    labels = {t.id: (t.label or t.id) for t in model.threads}
    vars_shown: List[str] = []
    for s in steps:
        if s["kind"] in ("READ", "WRITE") and s["target"] not in vars_shown:
            vars_shown.append(s["target"])
    initial = {sv.name: sv.initial for sv in model.shared}

    n_lanes = max(1, len(order))
    ribbon_x0 = LEFT + n_lanes * LANE_W + 16
    ribbons_w = RIBBON_W * len(vars_shown)
    annot_w = 236 if schedule.get("kind") in ("RACE", "DEADLOCK") else 0
    width = int(ribbon_x0 + ribbons_w + annot_w + 24)
    body_h = max(1, len(steps)) * ROW_H
    legend_h = 70
    height = int(TOP + body_h + legend_h + 20)
    width = max(width, 700)

    kind = schedule.get("kind", "SAFE")
    out: List[str] = []
    out.append(
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" '
        f'viewBox="0 0 {width} {height}" role="img" aria-label={quoteattr(_title(kind))}>'
    )
    out.append(f"<title>{escape(_title(kind))}</title>")
    out.append(
        "<defs>"
        '<pattern id="hatch" width="8" height="8" patternUnits="userSpaceOnUse" patternTransform="rotate(45)">'
        f'<rect width="8" height="8" fill="#fee2e2"/><line x1="0" y1="0" x2="0" y2="8" stroke="{HAZARD}" stroke-width="2" stroke-opacity="0.55"/></pattern>'
        f'<marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="#7c3aed"/></marker>'
        f'<marker id="arrowred" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="{HAZARD}"/></marker>'
        "</defs>"
    )
    out.append(f'<rect x="0" y="0" width="{width}" height="{height}" rx="10" fill="{BG}" stroke="{GRID}"/>')
    out.append(_t(16, 26, _title(kind), 15, "bold"))
    out.append(_t(16, 44, "time flows downward; each box shows source line and operation", 11, fill=MUTED))

    lane_cx = {tid: LEFT + i * LANE_W + LANE_W / 2 for i, tid in enumerate(order)}
    # lane headers + guide lines
    for tid in order:
        cx = lane_cx[tid]
        out.append(f'<rect x="{cx - BOX_W / 2:.1f}" y="56" width="{BOX_W}" height="26" rx="6" fill="#1e293b"/>')
        out.append(_t(cx, 74, _trunc(labels.get(tid, tid), 24), 12, "bold", "#f8fafc", "middle"))
        out.append(
            f'<line x1="{cx:.1f}" y1="84" x2="{cx:.1f}" y2="{TOP + body_h:.1f}" stroke="{GRID}" stroke-dasharray="4 4"/>'
        )
    # value ribbons
    for k, var in enumerate(vars_shown):
        rx = ribbon_x0 + k * RIBBON_W
        out.append(f'<rect x="{rx:.1f}" y="56" width="{RIBBON_W - 12}" height="26" rx="6" fill="#0f766e"/>')
        out.append(_t(rx + (RIBBON_W - 12) / 2, 74, _trunc(var, 12), 12, "bold", "#f8fafc", "middle"))
        out.append(
            f'<line x1="{rx + (RIBBON_W - 12) / 2:.1f}" y1="84" x2="{rx + (RIBBON_W - 12) / 2:.1f}" y2="{TOP + body_h:.1f}" stroke="#99f6e4" stroke-width="3"/>'
        )
        init = initial.get(var, 0)
        init = int(init) if isinstance(init, float) and init == int(init) else init
        out.append(
            f'<rect x="{rx + 6:.1f}" y="{TOP - 8:.1f}" width="{RIBBON_W - 24}" height="18" rx="9" fill="#ccfbf1" stroke="#0d9488"/>'
        )
        out.append(_t(rx + (RIBBON_W - 12) / 2, TOP + 5, f"init {init}", 11, "normal", INK, "middle"))

    box_pos: Dict[int, Dict[str, float]] = {}
    last_unlock: Dict[str, int] = {}
    for i, s in enumerate(steps):
        y = TOP + i * ROW_H + 8
        cx = lane_cx.get(s["thread"], LEFT)
        x = cx - BOX_W / 2
        fill, stroke = KIND_STYLE.get(s["kind"], ("#e2e8f0", "#64748b"))
        hazard = bool(s.get("hazard"))
        blocked = bool(s.get("blocked"))
        out.append(_t(LEFT - 12, y + BOX_H / 2 + 4, str(i + 1), 11, fill=MUTED, anchor="end"))
        attrs = f'fill="url(#hatch)"' if hazard else f'fill="{fill}"'
        sc = HAZARD if hazard else stroke
        dash = ' stroke-dasharray="5 3"' if blocked else ""
        out.append(
            f'<rect x="{x:.1f}" y="{y:.1f}" width="{BOX_W}" height="{BOX_H}" rx="6" {attrs} stroke="{sc}" stroke-width="{2.2 if hazard else 1.4}"{dash}/>'
        )
        head = f'L{s["line"]}  {s["kind"]} {s["target"]}'.strip()
        if blocked:
            head += "  BLOCKED"
        out.append(_t(x + 8, y + 15, _trunc(head, 30), 12, "bold"))
        detail = s.get("text", "")
        if s["kind"] == "READ" and "local" in s:
            detail = f'{detail}  (= {s["local"]})'
        elif s["kind"] == "WRITE" and "wrote" in s:
            detail = f'{detail}  -> {s["wrote"]}'
        elif blocked and s.get("waitingFor"):
            detail = f'waits for {s["waitingFor"]}'
        out.append(_t(x + 8, y + 30, _trunc(detail, 31), 10.5, fill=MUTED))
        box_pos[i] = {"x": x, "y": y, "cx": cx}
        # lock handoff arrow: from the last UNLOCK of this lock (other thread) to this LOCK
        if s["kind"] == "LOCK" and not blocked and s["target"] in last_unlock:
            j = last_unlock[s["target"]]
            if steps[j]["thread"] != s["thread"]:
                a, b = box_pos[j], box_pos[i]
                x1 = a["x"] + (BOX_W if b["cx"] > a["cx"] else 0)
                x2 = b["x"] + (0 if b["cx"] > a["cx"] else BOX_W)
                out.append(
                    f'<path d="M{x1:.1f},{a["y"] + BOX_H / 2:.1f} C{(x1 + x2) / 2:.1f},{a["y"] + BOX_H / 2:.1f} '
                    f'{(x1 + x2) / 2:.1f},{b["y"] + BOX_H / 2:.1f} {x2:.1f},{b["y"] + BOX_H / 2:.1f}" fill="none" '
                    f'stroke="#7c3aed" stroke-width="1.6" marker-end="url(#arrow)"/>'
                )
                out.append(_t((x1 + x2) / 2, (a["y"] + b["y"]) / 2 + BOX_H / 2 - 4, f'{s["target"]} handoff', 9.5, fill="#7c3aed", anchor="middle"))
        if s["kind"] == "UNLOCK":
            last_unlock[s["target"]] = i
        # ribbon value after each write
        if s["kind"] == "WRITE" and s["target"] in vars_shown and "wrote" in s:
            k = vars_shown.index(s["target"])
            rx = ribbon_x0 + k * RIBBON_W + (RIBBON_W - 12) / 2
            col = HAZARD if hazard else "#0d9488"
            out.append(f'<line x1="{x + BOX_W:.1f}" y1="{y + BOX_H / 2:.1f}" x2="{rx - 26:.1f}" y2="{y + BOX_H / 2:.1f}" stroke="{col}" stroke-opacity="0.35" stroke-dasharray="2 3"/>')
            out.append(f'<rect x="{rx - 26:.1f}" y="{y + 8:.1f}" width="52" height="22" rx="11" fill="#ffffff" stroke="{col}" stroke-width="2"/>')
            out.append(_t(rx, y + 23, f'{s["target"]}={s["wrote"]}', 10.5, "bold", INK, "middle"))

    # side annotations
    ann_x = ribbon_x0 + ribbons_w + 6
    if kind == "RACE":
        exp = schedule.get("expected", {})
        act = schedule.get("actual", schedule.get("finalValues", {}))
        yy = TOP + 6
        for var in exp:
            out.append(f'<rect x="{ann_x:.1f}" y="{yy:.1f}" width="{annot_w - 14}" height="64" rx="8" fill="#fef2f2" stroke="{HAZARD}" stroke-width="2"/>')
            out.append(_t(ann_x + 10, yy + 22, f"expected {exp[var]}, got {act.get(var)}", 13, "bold", HAZARD))
            out.append(_t(ann_x + 10, yy + 40, _trunc(f"lost update on {var}", 24), 10.5, fill=MUTED))
            out.append(_t(ann_x + 10, yy + 54, "both threads read the old value", 10, fill=MUTED))
            yy += 76
    elif kind == "DEADLOCK":
        out.append(f'<rect x="{ann_x:.1f}" y="{TOP + 6:.1f}" width="{annot_w - 14}" height="64" rx="8" fill="#fef2f2" stroke="{HAZARD}" stroke-width="2"/>')
        out.append(_t(ann_x + 10, TOP + 28, "DEADLOCK", 13, "bold", HAZARD))
        out.append(_t(ann_x + 10, TOP + 46, "circular wait: no thread", 10.5, fill=MUTED))
        out.append(_t(ann_x + 10, TOP + 60, "can ever proceed", 10.5, fill=MUTED))
    else:
        fv = schedule.get("finalValues", {})
        if fv and annot_w:
            pass

    # legend
    ly = TOP + body_h + 16
    items = [
        ("READ", "read"),
        ("WRITE", "write"),
        ("LOCK", "lock"),
        ("UNLOCK", "unlock"),
    ]
    lx = 16
    for k, label in items:
        f, st = KIND_STYLE[k]
        out.append(f'<rect x="{lx}" y="{ly}" width="16" height="12" rx="3" fill="{f}" stroke="{st}"/>')
        out.append(_t(lx + 22, ly + 10, label, 11))
        lx += 78
    out.append(f'<rect x="{lx}" y="{ly}" width="16" height="12" rx="3" fill="url(#hatch)" stroke="{HAZARD}" stroke-width="2"/>')
    out.append(_t(lx + 22, ly + 10, "hazard step", 11))
    lx += 110
    out.append(f'<rect x="{lx}" y="{ly}" width="16" height="12" rx="3" fill="#fff" stroke="{MUTED}" stroke-dasharray="4 2"/>')
    out.append(_t(lx + 22, ly + 10, "blocked", 11))
    lx += 80
    out.append(f'<path d="M{lx},{ly + 6} L{lx + 22},{ly + 6}" stroke="#7c3aed" stroke-width="1.6" marker-end="url(#arrow)"/>')
    out.append(_t(lx + 30, ly + 10, "lock handoff", 11))
    out.append(_t(16, ly + 36, f"final values: {', '.join(f'{k}={v}' for k, v in schedule.get('finalValues', {}).items()) or 'n/a'}", 11, fill=MUTED))
    out.append("</svg>")
    return "".join(out)
