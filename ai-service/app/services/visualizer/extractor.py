"""Deterministic lightweight extractor: Java concurrency code -> VisModel."""
import re
from dataclasses import dataclass, field
from typing import Dict, List, Optional, Set, Tuple

from app.core.prompt_safety import SAFETY_SYSTEM, wrap_learner_data
from app.services.visualizer.javatext import (
    LineMap,
    Node,
    clean,
    match_close,
    parse_statements,
    split_top_level,
    walk_nodes,
)
from app.services.visualizer.models import (
    LLMVisModel,
    Op,
    SharedVar,
    ThreadModel,
    VisModel,
)

NUMERIC = r"(?:int|long|short|byte|double|float|Integer|Long|Double)"
FIELD_RE = re.compile(
    rf"^((?:(?:private|public|protected|static|volatile|final|transient)\s+)*){NUMERIC}\s+(\w+)\s*(?:=\s*(.+))?$",
    re.S,
)
LOCK_FIELD_RE = re.compile(
    r"^(?:(?:private|public|protected|static|final)\s+)*"
    r"(?:Object|ReentrantLock|Lock|Semaphore)\s+(\w+)\s*=",
)
CONTROL = {"if", "for", "while", "switch", "synchronized", "catch", "return", "new", "else", "try", "do"}
MAX_INLINE_DEPTH = 4
MAX_THREADS = 6


@dataclass
class Method:
    name: str
    mods: Set[str]
    body_span: Tuple[int, int]
    cls: str = ""


@dataclass
class ClassInfo:
    name: str
    extends: str = ""
    implements: str = ""
    methods: Dict[str, Method] = field(default_factory=dict)


@dataclass
class Site:
    offset: int
    end: int
    kind: str  # thread|submit
    arg: str
    arg_start: int
    label_hint: str = ""
    cls: str = ""
    var: str = ""


def _parse_int(s: Optional[str]) -> Optional[int]:
    if s is None:
        return None
    s = s.strip().rstrip("lLdDfF")
    try:
        return int(s)
    except ValueError:
        return None


def _num(s: Optional[str]) -> float:
    if s is None:
        return 0
    s = s.strip().rstrip("lLdDfF")
    try:
        v = float(s)
        return int(v) if v == int(v) else v
    except ValueError:
        return 0


class Extractor:
    def __init__(self, source: str) -> None:
        self.src = source
        self.text = clean(source)
        self.lines = LineMap(source)
        self.notes: List[str] = []
        self.classes: Dict[str, ClassInfo] = {}
        self.methods: Dict[str, Method] = {}  # by name (first wins)
        self.shared: Dict[str, SharedVar] = {}
        self.lock_fields: List[str] = []
        self.var_class: Dict[str, str] = {}
        self.runnable_vars: Dict[str, Tuple[int, int]] = {}
        self.thread_by_var: Dict[str, str] = {}
        self.sites: List[Site] = []
        # local variables currently holding a copy of a shared variable (`int tmp = count;`): local name -> shared name
        self._alias: Dict[str, str] = {}
        self._scan_structure()

    # ---------------------------------------------------------------- structure
    def _scan_structure(self) -> None:
        nodes = parse_statements(self.text, 0, len(self.text))
        self._scan_members(nodes, "")
        for m in re.finditer(r"\b(\w+)\s*(?:<[^>]*>)?\s+(\w+)\s*=\s*new\s+(\w+)\s*(?:<[^>]*>)?\s*\(", self.text):
            self.var_class[m.group(2)] = m.group(3)
        for m in re.finditer(r"\b(?:Runnable|Callable(?:<[^>]*>)?)\s+(\w+)\s*=\s*", self.text):
            end = self._stmt_end(m.end())
            self.runnable_vars[m.group(1)] = (m.end(), end)

    def _stmt_end(self, i: int) -> int:
        depth = 0
        for j in range(i, len(self.text)):
            ch = self.text[j]
            if ch in "([{":
                depth += 1
            elif ch in ")]}":
                depth -= 1
            elif ch == ";" and depth <= 0:
                return j
        return len(self.text)

    def _scan_members(self, nodes: List[Node], cls: str) -> None:
        for n in nodes:
            if n.kind == "decl":
                head = n.text
                cm = re.search(r"\b(class|interface|enum|record)\s+(\w+)(.*)$", head, re.S)
                if cm:
                    name = cm.group(2)
                    rest = cm.group(3)
                    em = re.search(r"\bextends\s+(\w+)", rest)
                    im = re.search(r"\bimplements\s+([\w\s,<>]+)", rest)
                    self.classes[name] = ClassInfo(
                        name, em.group(1) if em else "", im.group(1) if im else ""
                    )
                    self._scan_members(parse_statements(self.text, *n.body_span), name)
                elif "(" in head and n.body_span:
                    pre = head[: head.index("(")]
                    words = re.findall(r"[\w$]+", pre)
                    if not words or words[-1] in CONTROL:
                        continue
                    meth = Method(words[-1], set(words[:-1]), n.body_span, cls)
                    self.methods.setdefault(meth.name, meth)
                    if cls in self.classes:
                        self.classes[cls].methods.setdefault(meth.name, meth)
            elif n.kind == "simple" and cls:
                fm = FIELD_RE.match(n.text)
                if fm:
                    mods = set(fm.group(1).split())
                    if "final" not in mods:
                        self.shared.setdefault(
                            fm.group(2),
                            SharedVar(name=fm.group(2), initial=_num(fm.group(3)), volatile="volatile" in mods),
                        )
                    continue
                lm = LOCK_FIELD_RE.match(n.text)
                if lm:
                    self.lock_fields.append(lm.group(1))
            elif n.kind in ("simple",) and not cls:
                # snippet without enclosing class: treat declarations as fields
                fm = FIELD_RE.match(n.text)
                if fm and "final" not in fm.group(1):
                    self.shared.setdefault(
                        fm.group(2),
                        SharedVar(name=fm.group(2), initial=_num(fm.group(3)), volatile="volatile" in fm.group(1)),
                    )
                lm = LOCK_FIELD_RE.match(n.text)
                if lm:
                    self.lock_fields.append(lm.group(1))

    # ---------------------------------------------------------------- sites
    def _find_sites(self) -> None:
        text = self.text
        thread_classes = {c.name for c in self.classes.values() if c.extends == "Thread"}
        for m in re.finditer(r"\bnew\s+Thread\s*\(", text):
            p = m.end() - 1
            q = match_close(text, p)
            if q < 0:
                continue
            args = split_top_level(text[p + 1 : q])
            first = args[0] if args else ""
            label_hint = ""
            if len(args) > 1:
                nm = re.findall(r'"([^"]*)"', self.src[p + 1 : q])
                if nm:
                    label_hint = nm[-1]
            before = text[max(0, m.start() - 60) : m.start()]
            vm = re.search(r"(\w+)\s*=\s*$", before)
            var = vm.group(1) if vm else ""
            arg_start = p + 1 + (text[p + 1 : q].find(first) if first else 0)
            if first.startswith('"') or not first:
                continue
            self.sites.append(Site(m.start(), q + 1, "thread", first, arg_start, label_hint or var, var=var))
            if var:
                self.thread_by_var[var] = ""  # filled later
        for cname in thread_classes:
            for m in re.finditer(rf"\bnew\s+{cname}\s*\(", text):
                q = match_close(text, m.end() - 1)
                if q < 0:
                    continue
                before = text[max(0, m.start() - 60) : m.start()]
                vm = re.search(r"(\w+)\s*=\s*$", before)
                self.sites.append(
                    Site(m.start(), q + 1, "thread", "", m.end(), vm.group(1) if vm else "", cls=cname,
                         var=vm.group(1) if vm else "")
                )
                if vm:
                    self.thread_by_var[vm.group(1)] = ""
        for m in re.finditer(r"\b(\w+)\s*\.\s*(submit|execute|runAsync|supplyAsync|schedule)\s*\(", text):
            if m.group(1) in ("Thread",):
                continue
            p = m.end() - 1
            q = match_close(text, p)
            if q < 0:
                continue
            args = split_top_level(text[p + 1 : q])
            first = args[0] if args else ""
            if not first:
                continue
            arg_start = p + 1 + text[p + 1 : q].find(first)
            self.sites.append(Site(m.start(), q + 1, "submit", first, arg_start))
        self.sites.sort(key=lambda s: s.offset)

    def _for_loops(self, nodes: List[Node]) -> List[Tuple[int, int, int]]:
        out = []
        for n in walk_nodes(nodes):
            if n.kind in ("for", "while"):
                bound = 2
                bm = re.search(r"[<]=?\s*(\d+)\s*(?:;|$)", n.text)
                if n.kind == "for" and bm:
                    bound = max(1, min(int(bm.group(1)) + (1 if "<=" in n.text else 0), 3))
                out.append((n.start, n.end, bound))
        return out

    # ---------------------------------------------------------------- bodies
    def _resolve_body(self, site: Site):
        """Return list of (nodes_span_start, end, this_name) bodies to walk, or None."""
        text = self.text
        if site.cls:
            meth = self.classes[site.cls].methods.get("run")
            if meth:
                return [("span", meth.body_span, "this", meth)]
            return None
        arg = site.arg.strip()
        return self._resolve_arg(arg, site.arg_start, "this", depth=0)

    def _resolve_arg(self, arg: str, arg_start: int, this_name: str, depth: int):
        text = self.text
        if depth > 3 or not arg:
            return None
        arrow = arg.find("->")
        if arrow >= 0 and not arg.lstrip().startswith("new"):
            body = arg[arrow + 2 :]
            off = arg_start + arrow + 2
            lead = len(body) - len(body.lstrip())
            body_s = body.strip()
            off += lead
            if body_s.startswith("{"):
                q = match_close(text, off)
                return [("span", (off + 1, q if q > 0 else off + len(body_s)), this_name, None)]
            return [("span", (off, off + len(body_s)), this_name, None, True)]
        if arg.startswith("new "):
            nm = re.match(r"new\s+(\w+)", arg)
            brace = arg.find("{")
            if brace >= 0 and re.match(r"new\s+\w+\s*(?:<[^>]*>)?\s*\(", arg):
                bo = arg_start + brace
                bc = match_close(text, bo)
                inner = parse_statements(text, bo + 1, bc if bc > 0 else len(text))
                for n in inner:
                    if n.kind == "decl" and re.search(r"\b(run|call)\s*\(", n.text) and n.body_span:
                        return [("span", n.body_span, this_name, None)]
                return None
            if nm and nm.group(1) in self.classes:
                meth = self.classes[nm.group(1)].methods.get("run")
                if meth:
                    return [("span", meth.body_span, "this", meth)]
            return None
        mr = re.match(r"^(\w+)\s*::\s*(\w+)$", arg)
        if mr:
            recv, name = mr.groups()
            if name in self.methods:
                return [("call", name, "this" if recv == "this" else recv, None)]
            return None
        if re.match(r"^\w+$", arg):
            if arg in self.runnable_vars:
                s, e = self.runnable_vars[arg]
                return self._resolve_arg(text[s:e].strip(), s + (len(text[s:e]) - len(text[s:e].lstrip())), this_name, depth + 1)
            cls = self.var_class.get(arg)
            if cls in self.classes and "run" in self.classes[cls].methods:
                return [("span", self.classes[cls].methods["run"].body_span, arg, self.classes[cls].methods["run"])]
            if arg == "this":
                meth = self.methods.get("run")
                if meth:
                    return [("span", meth.body_span, "this", meth)]
        return None

    # ---------------------------------------------------------------- op walking
    def _ops_for_text(self, stmt: str, start: int, this_name: str, depth: int, stack: Set[str]) -> List[Op]:
        """Analyse one simple statement into ordered ops."""
        events: List[Tuple[float, List[Op]]] = []
        original_stmt = stmt
        absolute_end = start + len(stmt)
        inside = [
            s for s in self.sites
            if s.offset >= start and s.end <= absolute_end + 1
        ]
        chars = list(stmt)
        for s in inside:
            for k in range(s.offset - start, min(len(chars), s.end - start)):
                chars[k] = " "
        stmt = "".join(chars)
        # a Runnable/Callable declaration only defines a task; it does not execute it here
        rv = re.match(r"\s*(?:final\s+)?(?:Runnable|Callable(?:<[^>]*>)?)\s+\w+\s*=", stmt)
        if rv:
            stmt = stmt[: rv.end()] + " " * (len(stmt) - rv.end())
        line = self.lines.line(start)
        src_text = re.sub(r"\s+", " ", self.src[start : start + len(stmt)]).strip() if stmt else ""
        claimed: List[Tuple[int, int]] = []

        upd = self._alias_update(stmt, line, src_text) if self._alias else None
        if upd is not None:
            return upd
        self._register_alias(stmt)

        def mk(kind, target="", text="", **kw) -> Op:
            return Op(kind=kind, target=target, line=line, text=text or src_text, source=src_text, **kw)

        def overlaps(a: int, b: int) -> bool:
            return any(a < y and b > x for x, y in claimed)

        def lock_name(expr: str) -> str:
            expr = expr.strip()
            return this_name if expr == "this" else expr

        # lock / unlock / wait / notify / sleep / join
        for m in re.finditer(r"\b(\w+)\s*\.\s*(lock|lockInterruptibly|tryLock|acquire)\s*\(", stmt):
            events.append((m.start(), [mk("LOCK", lock_name(m.group(1)), f"{m.group(1)}.lock()")]))
            claimed.append((m.start(), m.end()))
        for m in re.finditer(r"\b(\w+)\s*\.\s*(unlock|release)\s*\(", stmt):
            events.append((m.start(), [mk("UNLOCK", lock_name(m.group(1)), f"{m.group(1)}.unlock()")]))
            claimed.append((m.start(), m.end()))
        for m in re.finditer(r"(?:\b(\w+)\s*\.\s*)?\bwait\s*\(", stmt):
            events.append((m.start(), [mk("WAIT", lock_name(m.group(1) or "this"), "wait()")]))
            claimed.append((m.start(), m.end()))
        for m in re.finditer(r"(?:\b(\w+)\s*\.\s*)?\b(notify|notifyAll)\s*\(", stmt):
            events.append((m.start(), [mk("NOTIFY", lock_name(m.group(1) or "this"), m.group(2) + "()")]))
            claimed.append((m.start(), m.end()))
        for m in re.finditer(r"\bThread\s*\.\s*sleep\s*\(\s*([^)]*)\)", stmt):
            events.append((m.start(), [mk("SLEEP", m.group(1).strip() + " ms", f"Thread.sleep({m.group(1).strip()})")]))
            claimed.append((m.start(), m.end()))
        for m in re.finditer(r"\b(\w+)\s*\.\s*join\s*\(", stmt):
            events.append((m.start(), [mk("JOIN", self.thread_by_var.get(m.group(1)) or m.group(1), f"{m.group(1)}.join()")]))
            claimed.append((m.start(), m.end()))
        for m in re.finditer(r"\b(\w+)\s*\.\s*start\s*\(\s*\)", stmt):
            events.append((m.start(), [mk("START", self.thread_by_var.get(m.group(1)) or m.group(1), f"{m.group(1)}.start()")]))
            claimed.append((m.start(), m.end()))

        # thread creation sites inside this statement (new Thread(..).start(), submit)
        for site in inside:
            tid = self._site_ids.get(site.offset)
            if not tid:
                continue
            if site.kind == "submit":
                events.append((site.offset - start, [mk("START", tid, f"submit -> {tid}")]))
            elif re.match(r"\s*\.\s*start\s*\(", original_stmt[site.end - start :]):
                events.append((site.offset - start, [mk("START", tid, f"start {tid}")]))

        # inlined calls to methods defined in the file
        if depth < MAX_INLINE_DEPTH:
            for m in re.finditer(r"(?:\b(\w+)\s*\.\s*)?\b(\w+)\s*\(", stmt):
                name = m.group(2)
                if name in CONTROL or name not in self.methods or overlaps(m.start(), m.end()):
                    continue
                if name in stack:
                    continue
                if m.start() > 0 and stmt[max(0, m.start() - 4) : m.start()].strip().endswith("new"):
                    continue
                meth = self.methods[name]
                recv = m.group(1)
                inner_this = this_name if recv in (None, "this") else recv
                events.append(
                    (m.start(), self._method_ops(meth, inner_this, depth + 1, stack | {name}, start))
                )
                claimed.append((m.start(), m.end()))

        # shared variable accesses
        for v in list(self.shared):
            pfx = r"(?<![\w.])(?:(?:this|\w+)\s*\.\s*)?"
            pat_incdec = re.compile(rf"{pfx}{re.escape(v)}\s*(\+\+|--)|(\+\+|--)\s*{pfx}{re.escape(v)}\b")
            pat_assign = re.compile(rf"{pfx}{re.escape(v)}\s*(\+=|-=|\*=|/=|=(?!=))\s*([^;]*)")
            pat_any = re.compile(rf"{pfx}{re.escape(v)}\b(?!\s*\()(?!\s*\.)")
            local_claimed: List[Tuple[int, int]] = []
            for m in pat_incdec.finditer(stmt):
                d = 1 if "++" in m.group(0) else -1
                events.append((m.start(), self._rmw(v, d, None, line, src_text)))
                local_claimed.append((m.start(), m.end()))
            for m in pat_assign.finditer(stmt):
                if any(m.start() < y and m.end() > x for x, y in local_claimed):
                    continue
                opr, expr = m.group(1), m.group(2).strip()
                mentions = re.search(rf"(?<![\w.]){re.escape(v)}\b", expr) is not None
                lit = _parse_int(expr)
                if opr == "+=":
                    events.append((m.start(), self._rmw(v, lit, None, line, src_text, approx=lit is None)))
                elif opr == "-=":
                    events.append((m.start(), self._rmw(v, -lit if lit is not None else None, None, line, src_text, approx=lit is None)))
                elif opr in ("*=", "/="):
                    events.append((m.start(), self._rmw(v, None, None, line, src_text, approx=True)))
                elif mentions:
                    dm = re.fullmatch(rf"(?:\w+\.)?{re.escape(v)}\s*([+-])\s*(\d+)", expr)
                    dm2 = re.fullmatch(rf"(\d+)\s*\+\s*(?:\w+\.)?{re.escape(v)}", expr)
                    delta = None
                    if dm:
                        delta = int(dm.group(2)) * (1 if dm.group(1) == "+" else -1)
                    elif dm2:
                        delta = int(dm2.group(1))
                    events.append((m.start(), self._rmw(v, delta, None, line, src_text, approx=delta is None)))
                else:
                    ops = self._alias_write(v, expr, line, src_text) if self._alias else None
                    if ops is None:
                        ops = [mk("WRITE", v, f"{v} = {expr}" if expr else v, assign=lit)]
                    events.append((m.start(), ops))
                local_claimed.append((m.start(), m.end()))
            for m in pat_any.finditer(stmt):
                if any(m.start() < y and m.end() > x for x, y in local_claimed):
                    continue
                if overlaps(m.start(), m.end()):
                    continue
                events.append((m.start(), [mk("READ", v, f"read {v}")]))
        events.sort(key=lambda e: e[0])
        ops: List[Op] = []
        for _, evs in events:
            ops.extend(evs)
        return ops

    # ----------------------------------------------------- private copies of a shared variable
    def _register_alias(self, stmt: str) -> None:
        """`int tmp = count;` makes `tmp` this thread's private copy of the shared `count`."""
        m = re.match(r"\s*(?:final\s+)?(?:int|long|Integer|Long)\s+(\w+)\s*=\s*(?:(?:this|\w+)\s*\.\s*)?(\w+)\s*$", stmt)
        if m and m.group(2) in self.shared and m.group(1) not in self.shared:
            self._alias[m.group(1)] = m.group(2)

    @staticmethod
    def _delta_of(expr: str, name: str) -> Optional[int]:
        """`name + 3`, `name - 2` or `3 + name` -> the signed amount; a bare `name` -> 0; anything else -> None."""
        n = re.escape(name)
        expr = expr.strip()
        if expr == name:
            return 0
        m = re.fullmatch(rf"{n}\s*([+-])\s*(\d+)", expr)
        if m:
            return int(m.group(2)) * (1 if m.group(1) == "+" else -1)
        m = re.fullmatch(rf"(\d+)\s*\+\s*{n}", expr)
        return int(m.group(1)) if m else None

    @staticmethod
    def _calc(a: str, delta: int) -> str:
        return f"{a} = {a} {'+' if delta >= 0 else '-'} {abs(delta)}"

    def _alias_update(self, stmt: str, line: int, src_text: str) -> Optional[List[Op]]:
        """A statement that only changes a private copy (`tmp = tmp + 1`, `tmp++`, `tmp += 2`): the calculation."""
        for a, v in self._alias.items():
            n = re.escape(a)
            delta: Optional[int] = None
            m = re.fullmatch(rf"\s*{n}\s*=\s*(.+?)\s*", stmt)
            if m:
                delta = self._delta_of(m.group(1), a)
            m = re.fullmatch(rf"\s*{n}\s*([+-])=\s*(\d+)\s*", stmt)
            if m:
                delta = int(m.group(2)) * (1 if m.group(1) == "+" else -1)
            m = re.fullmatch(rf"\s*(?:{n}\s*(\+\+|--)|(\+\+|--)\s*{n})\s*", stmt)
            if m:
                delta = 1 if "++" in (m.group(1) or m.group(2)) else -1
            if delta is not None and delta != 0:
                return [Op(kind="COMPUTE", target=v, line=line, text=self._calc(a, delta), delta=delta, source=src_text)]
            touches = re.match(rf"\s*{n}\s*(?:[-+*/]?=|\+\+|--)", stmt) or re.match(rf"\s*(?:\+\+|--)\s*{n}\b", stmt)
            if touches and delta is None:
                self.notes.append(f"line {line}: could not evaluate the calculation on '{a}' exactly; assumed +1")
                return [Op(kind="COMPUTE", target=v, line=line, text=self._calc(a, 1), delta=1, source=src_text)]
        return None

    def _alias_write(self, v: str, expr: str, line: int, src_text: str) -> Optional[List[Op]]:
        """`count = tmp;` or `count = tmp + 1;`: writes back a private copy, optionally calculating it first."""
        for a, av in self._alias.items():
            if av != v:
                continue
            delta = self._delta_of(expr, a)
            if delta is None and re.search(rf"(?<![\w.]){re.escape(a)}\b", expr):
                self.notes.append(f"line {line}: could not evaluate the update expression exactly; assumed +1 per execution")
                delta = 1
            if delta is None:
                continue
            ops = [Op(kind="WRITE", target=v, line=line, text=f"{v} = {a}", delta=0, source=src_text)]
            if delta != 0:
                ops.insert(0, Op(kind="COMPUTE", target=v, line=line, text=self._calc(a, delta), delta=delta, source=src_text))
            return ops
        return None

    def _rmw(self, v: str, delta: Optional[int], assign, line: int, src_text: str, approx: bool = False) -> List[Op]:
        if delta is None:
            wtext = f"{v} = tmp ± ?"
        else:
            wtext = f"{v} = tmp {'+' if delta >= 0 else '-'} {abs(delta)}"
        if approx:
            self.notes.append(f"line {line}: could not evaluate the update expression exactly; assumed +1 per execution")
        return [
            Op(kind="READ", target=v, line=line, text=f"tmp = {v}", source=src_text),
            Op(kind="WRITE", target=v, line=line, text=wtext, delta=delta if delta is not None else 1, source=src_text),
        ]

    def _method_ops(self, meth: Method, this_name: str, depth: int, stack: Set[str], call_offset: int) -> List[Op]:
        nodes = parse_statements(self.text, *meth.body_span)
        saved, self._alias = self._alias, {}
        try:
            ops = self._walk(nodes, this_name, depth, stack)
        finally:
            self._alias = saved
        if "synchronized" in meth.mods:
            lock = f"{meth.cls}.class" if "static" in meth.mods and meth.cls else this_name
            line = self.lines.line(meth.body_span[0])
            ops = [Op(kind="LOCK", target=lock, line=line, text=f"synchronized {meth.name}()")] + ops + [
                Op(kind="UNLOCK", target=lock, line=self.lines.line(meth.body_span[1]), text=f"end synchronized {meth.name}()")
            ]
        return ops

    def _walk(self, nodes: List[Node], this_name: str, depth: int, stack: Set[str]) -> List[Op]:
        ops: List[Op] = []
        for n in nodes:
            if n.kind == "simple":
                ops.extend(self._ops_for_text(self.text[n.start : n.end - (1 if self.text[n.end - 1 : n.end] == ";" else 0)], n.start, this_name, depth, stack))
            elif n.kind == "block":
                ops.extend(self._walk(n.body, this_name, depth, stack))
            elif n.kind == "sync":
                lock = this_name if n.text.strip() == "this" else n.text.strip()
                line = self.lines.line(n.start)
                ops.append(Op(kind="LOCK", target=lock, line=line, text=f"synchronized ({n.text.strip()})"))
                ops.extend(self._walk(n.body, this_name, depth, stack))
                ops.append(Op(kind="UNLOCK", target=lock, line=self.lines.line(max(n.start, n.end - 1)), text=f"end synchronized ({n.text.strip()})"))
            elif n.kind == "if":
                cond_at = self.text.find("(", n.start) + 1
                ops.extend(self._ops_for_text(n.text, cond_at, this_name, depth, stack))
                ops.extend(self._walk(n.body, this_name, depth, stack))
                if n.orelse:
                    self.notes.append(f"line {self.lines.line(n.start)}: only the 'if' branch is modelled, 'else' is ignored")
            elif n.kind in ("for", "while", "do"):
                ops.extend(self._walk(n.body, this_name, depth, stack))
                self.notes.append(f"line {self.lines.line(n.start)}: loop body modelled as a single iteration")
            elif n.kind == "try":
                ops.extend(self._walk(n.body, this_name, depth, stack))
                if n.finally_body:
                    ops.extend(self._walk(n.finally_body, this_name, depth, stack))
        return ops

    def _walk_body(self, body) -> List[Op]:
        ops: List[Op] = []
        for item in body:
            kind = item[0]
            if kind == "span":
                self._alias = {}
                span, this_name = item[1], item[2]
                if len(item) > 4 and item[4]:  # expression lambda
                    seg = self.text[span[0] : span[1]]
                    ops.extend(self._ops_for_text(seg, span[0], this_name, 0, set()))
                else:
                    meth = item[3]
                    if meth is not None and "synchronized" in meth.mods:
                        ops.extend(self._method_ops(meth, this_name, 1, {meth.name}, span[0]))
                    else:
                        ops.extend(self._walk(parse_statements(self.text, *span), this_name, 0, set()))
            elif kind == "call":
                name, this_name = item[1], item[2]
                ops.extend(self._method_ops(self.methods[name], this_name, 1, {name}, 0))
        return ops

    # ---------------------------------------------------------------- main
    def extract(self) -> VisModel:
        text = self.text
        self._site_ids: Dict[int, str] = {}
        self._find_sites()
        top_nodes = parse_statements(text, 0, len(text))
        loops = self._for_loops(self._all_method_nodes())
        threads: List[ThreadModel] = []
        used: Set[str] = set()

        def unique(label: str) -> str:
            base, k = label, 2
            while label in used:
                label = f"{base}-{k}"
                k += 1
            used.add(label)
            return label

        counter = 0
        for site in self.sites:
            body = self._resolve_body(site)
            if body is None:
                self.notes.append(f"line {self.lines.line(site.offset)}: could not resolve the task run by this thread")
                continue
            reps = 1
            for (ls, le, bound) in loops:
                if ls <= site.offset < le:
                    reps = max(reps, bound)
            for r in range(reps):
                if len(threads) >= MAX_THREADS:
                    break
                counter += 1
                base = site.label_hint or (f"Thread-{counter}" if site.kind == "thread" else f"worker-{counter}")
                label = base if reps == 1 else f"{base}-{r + 1}"
                tid = unique(label)
                if r == 0:
                    self._site_ids[site.offset] = tid
                    if site.var:
                        self.thread_by_var[site.var] = tid
                ops = self._walk_body(body)
                threads.append(ThreadModel(id=tid, label=label, ops=ops))
            if reps > 1:
                self.notes.append(f"line {self.lines.line(site.offset)}: thread created in a loop, modelled as {reps} threads")
        # main thread lane (START/JOIN and any shared access) when it exists
        main = self.methods.get("main")
        if main and threads:
            mops = self._method_ops(main, "this", 1, {"main"}, 0)
            if mops:
                threads.insert(0, ThreadModel(id="main", label="main", ops=mops))

        workers = [t for t in threads if t.id != "main"]
        used_targets = {o.target for t in workers for o in t.ops if o.kind in ("READ", "WRITE")}
        used_locks = []
        for t in threads:
            for o in t.ops:
                if o.kind in ("LOCK", "UNLOCK", "WAIT", "NOTIFY") and o.target not in used_locks:
                    used_locks.append(o.target)
        shared = [s for s in self.shared.values() if s.name in used_targets or any(o.target == s.name for t in threads for o in t.ops)]
        if not workers:
            confidence = "low"
        elif any(o.kind in ("READ", "WRITE", "LOCK") for t in workers for o in t.ops):
            confidence = "high"
        else:
            confidence = "medium"
        notes = list(dict.fromkeys(self.notes))
        if main and workers:
            notes.append("main thread START/JOIN shown in the model; hazards are computed between worker threads")
        return VisModel(
            threads=threads,
            shared=shared,
            locks=used_locks,
            confidence=confidence,
            source="deterministic",
            notes=notes,
        )

    def _all_method_nodes(self) -> List[Node]:
        nodes: List[Node] = []
        for m in self.methods.values():
            nodes.extend(parse_statements(self.text, *m.body_span))
        return nodes


def extract_deterministic(code: str) -> VisModel:
    return Extractor(code).extract()


# ------------------------------------------------------------------ LLM fallback

def generic_low_confidence_model(reason: str) -> VisModel:
    return VisModel(
        threads=[],
        shared=[],
        locks=[],
        confidence="low",
        source="fallback",
        notes=[reason, "No threads could be recognised; nothing is drawn rather than inventing a diagram."],
    )


def llm_extract(code: str) -> VisModel:
    """Ask the LLM for the same JSON model; validated with pydantic. Input is
    wrapped as learner data. Raises AIServiceError on failure."""
    from app.services.ai_service import generate_json

    prompt = f"""
Extract a concurrency model from the Java code below. Do not execute or judge it.

{wrap_learner_data("source_code", code, 8000)}

Return JSON with exactly this structure:
{{
  "threads": [{{"id": "t1", "label": "...", "ops": [
      {{"kind": "READ|WRITE|LOCK|UNLOCK|WAIT|NOTIFY|SLEEP|START|JOIN", "target": "variable or lock name", "line": 1, "text": "short text", "delta": 1}}
  ]}}],
  "shared": [{{"name": "count", "initial": 0}}],
  "locks": ["lockName"]
}}

RULES:
1. Only include operations that literally appear in the code (line numbers are 1-based).
2. "count++" is a READ of count followed by a WRITE of count with delta 1.
3. If the code has no threads, return "threads": [].
4. Return only valid JSON.
"""
    raw = generate_json(prompt, LLMVisModel, system=SAFETY_SYSTEM)
    threads = [
        ThreadModel(
            id=t["id"],
            label=t.get("label") or t["id"],
            ops=[Op(**{**o, "delta": o.get("delta")}) for o in t["ops"]],
        )
        for t in raw["threads"]
    ][:MAX_THREADS]
    shared = [SharedVar(**s) for s in raw["shared"]]
    locks = list(raw["locks"])
    return VisModel(
        threads=threads,
        shared=shared,
        locks=locks,
        confidence="medium" if threads else "low",
        source="llm",
        notes=["Model extracted by the LLM because deterministic extraction found no threads; verify against your code."],
    )


def extract_model(code: str, use_llm: bool = True) -> VisModel:
    from app.core.exceptions import AIServiceError
    from app.services import ai_service

    model = extract_deterministic(code)
    if any(t.id != "main" for t in model.threads):
        return model
    if not use_llm:
        return generic_low_confidence_model("Deterministic extraction found no threads (LLM extraction disabled).")
    if not ai_service.is_llm_configured():
        return generic_low_confidence_model("Deterministic extraction found no threads and the LLM is not configured.")
    try:
        return llm_extract(code)
    except AIServiceError as exc:
        return generic_low_confidence_model(f"Deterministic extraction found no threads and LLM extraction failed ({exc.code}).")
