"""Deterministic control-flow diagram for (non-concurrent) Java snippets.

Line/brace based: handles if/else-if/else, for/while/do-while, return/throw,
method calls and plain statements. try/synchronized bodies are inlined; switch is
drawn as a single box. Return statements end their branch (no edge to End)."""
import re
from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional, Tuple
from xml.sax.saxutils import escape, quoteattr

from app.services.visualizer.javatext import LineMap, Node, clean, parse_statements, walk_nodes
from app.services.visualizer.renderer import BG, FONT, GRID, INK, MUTED

BW, BH = 210, 34
DW, DH = 210, 58
GAP = 26
LABEL_CHARS = 32


@dataclass
class Block:
    items: List[Dict[str, Any]] = field(default_factory=list)
    w: float = 0
    h: float = 0
    cx: float = 0
    terminal: bool = False
    first: Optional[int] = None  # unused hook


def _shift(items: List[Dict[str, Any]], dx: float, dy: float) -> List[Dict[str, Any]]:
    out = []
    for it in items:
        c = dict(it)
        for k in ("x", "x1", "x2"):
            if k in c:
                c[k] += dx
        for k in ("y", "y1", "y2"):
            if k in c:
                c[k] += dy
        if "pts" in c:
            c["pts"] = [(px + dx, py + dy) for px, py in c["pts"]]
        out.append(c)
    return out


class FlowBuilder:
    def __init__(self, src: str) -> None:
        self.src = src
        self.text = clean(src)
        self.lines = LineMap(src)
        self.nodes_meta: List[Dict[str, Any]] = []
        self.notes: List[str] = []

    # ------------------------------------------------------------ labelling
    def label(self, n: Node, text: Optional[str] = None) -> str:
        raw = self.src[n.start : n.end] if text is None else text
        raw = re.sub(r"\s+", " ", raw).strip().rstrip(";").strip()
        return raw if len(raw) <= LABEL_CHARS else raw[: LABEL_CHARS - 1] + "…"

    def meta(self, kind: str, label: str, line: int) -> int:
        self.nodes_meta.append({"id": len(self.nodes_meta) + 1, "kind": kind, "label": label, "line": line})
        return len(self.nodes_meta)

    # ------------------------------------------------------------ primitives
    def box(self, kind: str, label: str, line: int) -> Block:
        nid = self.meta(kind, label, line)
        return Block(
            items=[{"t": "node", "shape": kind, "x": 0, "y": 0, "w": BW, "h": BH, "label": label, "line": line, "id": nid}],
            w=BW, h=BH, cx=BW / 2, terminal=(kind == "return"),
        )

    def diamond(self, kind: str, label: str, line: int) -> Block:
        nid = self.meta(kind, label, line)
        return Block(
            items=[{"t": "node", "shape": "decision", "x": 0, "y": 0, "w": DW, "h": DH, "label": label, "line": line, "id": nid}],
            w=DW, h=DH, cx=DW / 2,
        )

    @staticmethod
    def arrow(x1, y1, x2, y2, label: str = "") -> Dict[str, Any]:
        return {"t": "line", "pts": [(x1, y1), (x2, y2)], "label": label, "arrow": True}

    @staticmethod
    def poly(pts, label: str = "", arrow: bool = True) -> Dict[str, Any]:
        return {"t": "line", "pts": list(pts), "label": label, "arrow": arrow}

    # ------------------------------------------------------------ sequences
    def seq(self, nodes: List[Node]) -> Block:
        blocks: List[Block] = []
        for n in nodes:
            for b in self.node_blocks(n):
                blocks.append(b)
                if b.terminal:
                    break
            if blocks and blocks[-1].terminal:
                break
        blocks = [b for b in blocks if b.h > 0]
        if not blocks:
            return Block()
        left = max(b.cx for b in blocks)
        right = max(b.w - b.cx for b in blocks)
        items: List[Dict[str, Any]] = []
        y = 0.0
        prev_bottom = None
        for b in blocks:
            if prev_bottom is not None:
                items.append(self.arrow(left, prev_bottom, left, y + GAP))
                y += GAP
            items.extend(_shift(b.items, left - b.cx, y))
            y += b.h
            prev_bottom = y
        return Block(items=items, w=left + right, h=y, cx=left, terminal=blocks[-1].terminal)

    def node_blocks(self, n: Node) -> List[Block]:
        line = self.lines.line(n.start)
        if n.kind == "simple":
            t = n.text.strip()
            if not t:
                return []
            if re.match(r"^(return|throw)\b", t):
                return [self.box("return", self.label(n), line)]
            if re.match(r"^(break|continue)\b", t):
                return [self.box("jump", self.label(n), line)]
            if re.match(r"^[\w.$<>\[\]]+\s*\(.*\)$", t, re.S) and "=" not in t.split("(")[0]:
                return [self.box("call", self.label(n), line)]
            return [self.box("stmt", self.label(n), line)]
        if n.kind == "block":
            return [self.seq(n.body)]
        if n.kind == "if":
            return [self.if_block(n, line)]
        if n.kind in ("for", "while"):
            return [self.loop_block(n, line)]
        if n.kind == "do":
            return [self.do_block(n, line)]
        if n.kind == "try":
            body = list(n.body) + (n.finally_body or [])
            self.notes.append(f"line {line}: try/catch drawn as straight-line code (catch blocks omitted)")
            return [self.seq(body)]
        if n.kind == "sync":
            b = self.box("stmt", f"synchronized ({n.text.strip()})"[:LABEL_CHARS], line)
            return [b, self.seq(n.body)]
        if n.kind == "switch":
            self.notes.append(f"line {line}: switch drawn as a single box")
            return [self.box("stmt", f"switch ({n.text.strip()})"[:LABEL_CHARS], line)]
        if n.kind == "decl":
            return []
        return []

    # ------------------------------------------------------------ branching
    def if_block(self, n: Node, line: int) -> Block:
        cond = self.label(n, f"if ({n.text})")
        D = self.diamond("if", cond, line)
        T = self.seq(n.body)
        E = self.seq(n.orelse) if n.orelse else None
        items: List[Dict[str, Any]] = []
        top_gap = GAP + 8
        if E is not None and E.h > 0 or (n.orelse is not None and E is not None):
            if T.h == 0:
                T = self.box("stmt", "(empty)", line)
            if E.h == 0:
                E = self.box("stmt", "(empty)", line)
            tc = T.cx
            ec = max(T.w + 40 + E.cx, tc + DW + 24)
            xm = (tc + ec) / 2
            minx = min(0, xm - DW / 2)
            shift = -minx
            width = max(ec + (E.w - E.cx), xm + DW / 2) + shift
            items += _shift(D.items, xm - DW / 2 + shift, 0)
            items += _shift(T.items, shift, DH + top_gap)
            items += _shift(E.items, ec - E.cx + shift, DH + top_gap)
            ty = DH + top_gap
            items.append(self.poly([(xm - DW / 2 + shift, DH / 2), (tc + shift, DH / 2), (tc + shift, ty)], "yes"))
            items.append(self.poly([(xm + DW / 2 + shift, DH / 2), (ec + shift, DH / 2), (ec + shift, ty)], "no"))
            bottom = ty + max(T.h, E.h)
            merge_y = bottom + GAP
            mx = xm + shift
            for blk, c in ((T, tc), (E, ec)):
                if not blk.terminal:
                    items.append(self.poly([(c + shift, ty + blk.h), (c + shift, merge_y), (mx, merge_y)], arrow=False))
            if T.terminal and E.terminal:
                return Block(items=items, w=width, h=bottom, cx=mx, terminal=True)
            items.append({"t": "join", "x": mx, "y": merge_y})
            return Block(items=items, w=width, h=merge_y + 4, cx=mx)
        # no else: bypass lane on the right
        if T.h == 0:
            T = self.box("stmt", "(empty)", line)
        tc = T.cx
        xm = tc
        minx = min(0, xm - DW / 2)
        shift = -minx
        lane = max(T.w, xm + DW / 2) + 34
        width = lane + 10 + shift
        ty = DH + top_gap
        items += _shift(D.items, xm - DW / 2 + shift, 0)
        items += _shift(T.items, shift, ty)
        items.append(self.arrow(xm + shift, DH, xm + shift, ty, "yes"))
        merge_y = ty + T.h + GAP
        mx = xm + shift
        items.append(self.poly([(xm + DW / 2 + shift, DH / 2), (lane + shift, DH / 2), (lane + shift, merge_y), (mx, merge_y)], "no", arrow=False))
        if not T.terminal:
            items.append(self.poly([(mx, ty + T.h), (mx, merge_y)], arrow=False))
        items.append({"t": "join", "x": mx, "y": merge_y})
        return Block(items=items, w=width, h=merge_y + 4, cx=mx)

    def loop_block(self, n: Node, line: int) -> Block:
        label = self.label(n, f"{n.kind} ({n.text})")
        D = self.diamond(n.kind, label, line)
        B = self.seq(n.body)
        cx = max(B.cx, DW / 2)
        left_edge = min(cx - B.cx, cx - DW / 2)
        right_edge = max(cx - B.cx + B.w, cx + DW / 2)
        llane = left_edge - 30
        rlane = right_edge + 30
        shift = -llane
        items: List[Dict[str, Any]] = []
        items += _shift(D.items, cx - DW / 2 + shift, 0)
        by = DH + GAP + 6
        if B.h > 0:
            items += _shift(B.items, cx - B.cx + shift, by)
            items.append(self.arrow(cx + shift, DH, cx + shift, by, "yes"))
            body_bottom = by + B.h
            exit_y = body_bottom + GAP + 14
            if not B.terminal:
                items.append(self.poly([(cx + shift, body_bottom), (cx + shift, body_bottom + 14), (llane + shift, body_bottom + 14), (llane + shift, DH / 2), (cx - DW / 2 + shift, DH / 2)]))
        else:
            exit_y = DH + GAP + 14
        items.append(self.poly([(cx + DW / 2 + shift, DH / 2), (rlane + shift, DH / 2), (rlane + shift, exit_y), (cx + shift, exit_y)], "no", arrow=False))
        items.append({"t": "join", "x": cx + shift, "y": exit_y})
        return Block(items=items, w=rlane + shift + 6, h=exit_y + 4, cx=cx + shift)

    def do_block(self, n: Node, line: int) -> Block:
        B = self.seq(n.body)
        if B.h == 0:
            B = self.box("stmt", "(empty)", line)
        label = self.label(n, f"do-while ({n.text})")
        D = self.diamond("do", label, line)
        cx = max(B.cx, DW / 2)
        left_edge = min(cx - B.cx, cx - DW / 2)
        llane = left_edge - 30
        shift = -llane
        items: List[Dict[str, Any]] = []
        items += _shift(B.items, cx - B.cx + shift, 0)
        dy = B.h + GAP
        items += _shift(D.items, cx - DW / 2 + shift, dy)
        if not B.terminal:
            items.append(self.arrow(cx + shift, B.h, cx + shift, dy))
        items.append(self.poly([(cx - DW / 2 + shift, dy + DH / 2), (llane + shift, dy + DH / 2), (llane + shift, -10), (cx + shift, -10), (cx + shift, 0)], "yes"))
        exit_y = dy + DH + GAP
        items.append(self.arrow(cx + shift, dy + DH, cx + shift, exit_y, "no"))
        return Block(items=items, w=max(cx - B.cx + B.w, cx + DW / 2) + shift + 10, h=exit_y, cx=cx + shift)


def find_method(src: str, text: str, name: Optional[str]):
    nodes = parse_statements(text, 0, len(text))
    methods = []

    def scan(ns: List[Node]):
        for n in ns:
            if n.kind == "decl" and n.body_span:
                if re.search(r"\b(class|interface|enum|record)\s+\w+", n.text):
                    scan(parse_statements(text, *n.body_span))
                elif "(" in n.text:
                    words = re.findall(r"[\w$]+", n.text[: n.text.index("(")])
                    if words and words[-1] not in ("if", "for", "while", "switch", "synchronized", "catch", "new"):
                        params = n.text[n.text.index("(") + 1 : n.text.rfind(")")] if ")" in n.text else ""
                        methods.append((words[-1], n.body_span, params))
    scan(nodes)
    return nodes, methods


def build_flow(code: str, method: Optional[str] = None) -> Dict[str, Any]:
    fb = FlowBuilder(code)
    top, methods = find_method(code, fb.text, method)
    chosen_name = None
    if methods:
        pick = None
        if method:
            pick = next((m for m in methods if m[0] == method), None)
            if pick is None:
                fb.notes.append(f"method '{method}' not found; showing '{methods[0][0]}'")
        if pick is None:
            pick = next((m for m in methods if m[0] == "main"), methods[0])
        chosen_name = pick[0]
        stmts = parse_statements(fb.text, *pick[1])
        start_label = f"{chosen_name}({pick[2].strip()})" if pick[2].strip() else f"{chosen_name}()"
    else:
        stmts = [n for n in top if n.kind != "decl"]
        start_label = "Start"
    root = fb.seq(stmts)
    confidence = "high" if fb.nodes_meta else "low"

    start = Block(items=[{"t": "node", "shape": "terminal", "x": 0, "y": 0, "w": BW, "h": 30, "label": _short(start_label), "line": 0, "id": 0}], w=BW, h=30, cx=BW / 2)
    end = Block(items=[{"t": "node", "shape": "terminal", "x": 0, "y": 0, "w": BW, "h": 30, "label": "End", "line": 0, "id": -1}], w=BW, h=30, cx=BW / 2)
    parts = [start] + ([root] if root.h > 0 else []) + ([] if root.terminal else [end])
    left = max(b.cx for b in parts)
    right = max(b.w - b.cx for b in parts)
    items: List[Dict[str, Any]] = []
    y = 0.0
    prev = None
    for b in parts:
        if prev is not None:
            items.append(FlowBuilder.arrow(left, prev, left, y + GAP))
            y += GAP
        items.extend(_shift(b.items, left - b.cx, y))
        y += b.h
        prev = y
    width = left + right + 40
    height = y + 70
    svg = _to_svg(items, width, height, chosen_name or "snippet")
    return {
        "method": chosen_name,
        "nodes": fb.nodes_meta,
        "svg": svg,
        "notes": list(dict.fromkeys(fb.notes)),
        "confidence": confidence,
    }


def _short(s: str) -> str:
    return s if len(s) <= LABEL_CHARS else s[: LABEL_CHARS - 1] + "…"


SHAPE_STYLE = {
    "stmt": ("#dbeafe", "#2563eb"),
    "call": ("#ede9fe", "#7c3aed"),
    "return": ("#fee2e2", "#dc2626"),
    "jump": ("#fef3c7", "#d97706"),
    "terminal": ("#1e293b", "#0f172a"),
    "decision": ("#ffedd5", "#ea580c"),
}


def _to_svg(items: List[Dict[str, Any]], w: float, h: float, name: str) -> str:
    ox, oy = 20, 44
    width, height = int(w + 40), int(h + oy)
    width = max(width, 320)
    out = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}" role="img" aria-label="Control flow diagram">',
        f"<title>Control flow: {escape(name)}</title>",
        '<defs><marker id="fa" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M0,0 L10,5 L0,10 z" fill="#475569"/></marker></defs>',
        f'<rect x="0" y="0" width="{width}" height="{height}" rx="10" fill="{BG}" stroke="{GRID}"/>',
        f'<text x="16" y="26" font-size="15" font-weight="bold" fill="{INK}" {FONT}>Control flow: {escape(name)}</text>',
    ]
    # lines first, nodes on top
    for it in items:
        if it["t"] == "line":
            pts = " ".join(f"{x + ox:.1f},{y + oy:.1f}" for x, y in it["pts"])
            marker = ' marker-end="url(#fa)"' if it.get("arrow") else ""
            out.append(f'<polyline points="{pts}" fill="none" stroke="#475569" stroke-width="1.5"{marker}/>')
            if it.get("label"):
                (x1, y1), (x2, y2) = it["pts"][0], it["pts"][1]
                out.append(
                    f'<text x="{x2 + ox + 4:.1f}" y="{y2 + oy - 6 if x1 == x2 else y1 + oy - 5:.1f}" font-size="11" fill="#475569" {FONT}>{escape(it["label"])}</text>'
                    if x1 == x2
                    else f'<text x="{(x1 + x2) / 2 + ox:.1f}" y="{y1 + oy - 5:.1f}" font-size="11" fill="#475569" text-anchor="middle" {FONT}>{escape(it["label"])}</text>'
                )
        elif it["t"] == "join":
            out.append(f'<circle cx="{it["x"] + ox:.1f}" cy="{it["y"] + oy:.1f}" r="4" fill="#475569"/>')
    for it in items:
        if it["t"] != "node":
            continue
        x, y, bw, bh = it["x"] + ox, it["y"] + oy, it["w"], it["h"]
        fill, stroke = SHAPE_STYLE.get(it["shape"], SHAPE_STYLE["stmt"])
        raw_label = it["label"]
        if it["shape"] == "decision" and len(raw_label) > 26:
            raw_label = raw_label[:25] + "…"
        label = escape(raw_label)
        tcol = "#f8fafc" if it["shape"] == "terminal" else INK
        if it["shape"] == "decision":
            cx, cy = x + bw / 2, y + bh / 2
            out.append(f'<polygon points="{cx:.1f},{y:.1f} {x + bw:.1f},{cy:.1f} {cx:.1f},{y + bh:.1f} {x:.1f},{cy:.1f}" fill="{fill}" stroke="{stroke}" stroke-width="1.5"/>')
        elif it["shape"] == "terminal":
            out.append(f'<rect x="{x:.1f}" y="{y:.1f}" width="{bw}" height="{bh}" rx="{bh / 2}" fill="{fill}" stroke="{stroke}"/>')
        else:
            rx = 14 if it["shape"] == "return" else 5
            out.append(f'<rect x="{x:.1f}" y="{y:.1f}" width="{bw}" height="{bh}" rx="{rx}" fill="{fill}" stroke="{stroke}" stroke-width="1.5"/>')
            if it["shape"] == "call":
                out.append(f'<line x1="{x + 8:.1f}" y1="{y:.1f}" x2="{x + 8:.1f}" y2="{y + bh:.1f}" stroke="{stroke}"/><line x1="{x + bw - 8:.1f}" y1="{y:.1f}" x2="{x + bw - 8:.1f}" y2="{y + bh:.1f}" stroke="{stroke}"/>')
        out.append(f'<text x="{x + bw / 2:.1f}" y="{y + bh / 2 + 4:.1f}" font-size="11.5" text-anchor="middle" fill="{tcol}" {FONT}>{label}</text>')
        if it.get("line") and it["shape"] != "decision":
            out.append(f'<text x="{x - 6:.1f}" y="{y + bh / 2 + 4:.1f}" font-size="10" text-anchor="end" fill="{MUTED}" {FONT}>L{it["line"]}</text>')
    out.append("</svg>")
    return "".join(out)
