"""Deterministic scheduler: SAFE, RACE (lost update) and DEADLOCK schedules."""
from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional, Set, Tuple

from app.services.visualizer.models import Op, ThreadModel, VisModel

SIM_KINDS = {"READ", "WRITE", "LOCK", "UNLOCK", "WAIT", "NOTIFY", "SLEEP"}


def worker_threads(model: VisModel) -> List[ThreadModel]:
    return [
        ThreadModel(id=t.id, label=t.label, ops=[o for o in t.ops if o.kind in SIM_KINDS])
        for t in model.threads
        if t.id != "main" and any(o.kind in SIM_KINDS for o in t.ops)
    ]


def _fmt(v):
    return int(v) if isinstance(v, float) and v == int(v) else v


class Engine:
    def __init__(self, threads: List[ThreadModel], initial: Dict[str, float]) -> None:
        self.threads = {t.id: t for t in threads}
        self.pc = {t.id: 0 for t in threads}
        self.values: Dict[str, float] = dict(initial)
        self.owner: Dict[str, str] = {}
        self.depth: Dict[str, int] = {}
        self.local: Dict[Tuple[str, str], float] = {}
        self.steps: List[Dict[str, Any]] = []

    def done(self, tid: str) -> bool:
        return self.pc[tid] >= len(self.threads[tid].ops)

    def next_op(self, tid: str) -> Optional[Op]:
        return None if self.done(tid) else self.threads[tid].ops[self.pc[tid]]

    def blocked(self, tid: str) -> bool:
        op = self.next_op(tid)
        return bool(op and op.kind == "LOCK" and self.owner.get(op.target) not in (None, tid))

    def _record(self, tid: str, op: Op, idx: int, **extra) -> Dict[str, Any]:
        step = {
            "index": len(self.steps),
            "thread": tid,
            "opIndex": idx,
            "kind": op.kind,
            "target": op.target,
            "line": op.line,
            "text": op.text,
            "hazard": False,
        }
        step.update(extra)
        self.steps.append(step)
        return step

    def step(self, tid: str) -> Optional[Dict[str, Any]]:
        """Execute the next op of a thread; None if finished or blocked."""
        op = self.next_op(tid)
        if op is None or self.blocked(tid):
            return None
        idx = self.pc[tid]
        self.pc[tid] += 1
        extra: Dict[str, Any] = {}
        if op.kind == "LOCK":
            self.owner[op.target] = tid
            self.depth[op.target] = self.depth.get(op.target, 0) + 1
            extra["holds"] = sorted(k for k, v in self.owner.items() if v == tid)
        elif op.kind == "UNLOCK":
            if self.owner.get(op.target) == tid:
                self.depth[op.target] -= 1
                if self.depth[op.target] <= 0:
                    del self.owner[op.target]
                    self.depth.pop(op.target, None)
            extra["holds"] = sorted(k for k, v in self.owner.items() if v == tid)
        elif op.kind == "READ":
            v = self.values.get(op.target, 0)
            self.local[(tid, op.target)] = v
            extra["value"] = _fmt(v)
            extra["local"] = _fmt(v)
        elif op.kind == "WRITE":
            base = self.local.get((tid, op.target), self.values.get(op.target, 0))
            if op.assign is not None:
                new = op.assign
            elif op.delta is not None:
                new = base + op.delta
            else:
                new = base + 1
            self.values[op.target] = new
            extra["value"] = _fmt(new)
            extra["wrote"] = _fmt(new)
        return self._record(tid, op, idx, **extra)

    def run_until(self, tid: str, op_index: int) -> bool:
        """Run thread until op `op_index` has executed. False if blocked first."""
        while self.pc[tid] <= op_index and not self.done(tid):
            if self.step(tid) is None:
                return False
        return True

    def run_to_end(self, tid: str) -> bool:
        while not self.done(tid):
            if self.step(tid) is None:
                return False
        return True

    def attempt_blocked(self, tid: str) -> Optional[Dict[str, Any]]:
        op = self.next_op(tid)
        if op is None:
            return None
        s = self._record(tid, op, self.pc[tid], blocked=True, waitingFor=self.owner.get(op.target))
        return s

    def final_values(self) -> Dict[str, Any]:
        return {k: _fmt(v) for k, v in self.values.items()}


def _initial(model: VisModel) -> Dict[str, float]:
    return {s.name: s.initial for s in model.shared}


def _locksets(thread: ThreadModel) -> List[Set[str]]:
    """Locks held (non-releasing) at each op index, including the op itself."""
    held: List[str] = []
    out: List[Set[str]] = []
    for op in thread.ops:
        if op.kind == "LOCK":
            held.append(op.target)
        out.append(set(held))
        if op.kind == "UNLOCK" and op.target in held:
            held.reverse()
            held.remove(op.target)
            held.reverse()
    return out


def safe_schedule(model: VisModel) -> Dict[str, Any]:
    workers = worker_threads(model)
    eng = Engine(workers, _initial(model))
    notes = []
    for t in workers:
        if not eng.run_to_end(t.id):
            notes.append(f"thread {t.id} blocked in the sequential run (lock never released in the snippet)")
            break
    return {"kind": "SAFE", "steps": eng.steps, "finalValues": eng.final_values(), "notes": notes}


def _rmw_pairs(thread: ThreadModel, var: str) -> List[Tuple[int, int]]:
    pairs = []
    ops = thread.ops
    for i, o in enumerate(ops):
        if o.kind == "READ" and o.target == var:
            for j in range(i + 1, len(ops)):
                if ops[j].kind == "WRITE" and ops[j].target == var:
                    pairs.append((i, j))
                    break
    return pairs


def find_races(model: VisModel) -> List[Dict[str, Any]]:
    workers = worker_threads(model)
    sets = {t.id: _locksets(t) for t in workers}
    races: List[Dict[str, Any]] = []
    variables = {o.target for t in workers for o in t.ops if o.kind in ("READ", "WRITE")}
    for var in sorted(variables):
        for a in range(len(workers)):
            for b in range(a + 1, len(workers)):
                A, B = workers[a], workers[b]
                acc_a = [(i, o) for i, o in enumerate(A.ops) if o.kind in ("READ", "WRITE") and o.target == var]
                acc_b = [(i, o) for i, o in enumerate(B.ops) if o.kind in ("READ", "WRITE") and o.target == var]
                conflict = None
                for ia, oa in acc_a:
                    for ib, ob in acc_b:
                        if "WRITE" not in (oa.kind, ob.kind):
                            continue
                        if sets[A.id][ia] & sets[B.id][ib]:
                            continue
                        conflict = (ia, ib)
                        break
                    if conflict:
                        break
                if conflict:
                    races.append({"var": var, "a": A.id, "b": B.id})
    return races


def _race_schedule(model: VisModel, race: Dict[str, Any], expected: Dict[str, Any]):
    workers = {t.id: t for t in worker_threads(model)}
    A, B, var = workers[race["a"]], workers[race["b"]], race["var"]
    pa, pb = _rmw_pairs(A, var), _rmw_pairs(B, var)
    sets = {A.id: _locksets(A), B.id: _locksets(B)}
    # pick an unprotected RMW pair in each thread (read/write not under a shared lock)
    cand = None
    for (ra, wa) in pa:
        for (rb, wb) in pb:
            if not (sets[A.id][ra] & sets[B.id][rb]) and not (sets[A.id][wa] & sets[B.id][wb]):
                cand = (ra, wa, rb, wb)
                break
        if cand:
            break
    if cand is None:
        return None
    ra, wa, rb, wb = cand
    eng = Engine([A, B], _initial(model))
    ok = (
        eng.run_until(A.id, ra)
        and eng.run_until(B.id, wb)
        and eng.run_to_end(A.id)
        and eng.run_to_end(B.id)
    )
    if not ok:
        return None
    # hazard steps: the two READs and two WRITEs of the racy RMW pairs
    idx_steps = [s for s in eng.steps if s["target"] == var and s["kind"] in ("READ", "WRITE")]
    for s in idx_steps:
        if (s["thread"] == A.id and s["opIndex"] in (ra, wa)) or (s["thread"] == B.id and s["opIndex"] in (rb, wb)):
            s["hazard"] = True
    actual = eng.final_values()
    return {
        "kind": "RACE",
        "steps": eng.steps,
        "finalValues": actual,
        "expected": {var: expected.get(var)},
        "var": var,
        "threads": [A.id, B.id],
    }


# --------------------------------------------------------------- deadlock

def _lock_edges(thread: ThreadModel) -> List[Dict[str, Any]]:
    held: List[Tuple[str, int]] = []
    edges = []
    for i, op in enumerate(thread.ops):
        if op.kind == "LOCK":
            if any(h == op.target for h, _ in held):
                held.append((op.target, i))  # reentrant
                continue
            for h, hi in held:
                if h != op.target:
                    edges.append({"thread": thread.id, "held": h, "heldIdx": hi, "wants": op.target, "wantsIdx": i})
            held.append((op.target, i))
        elif op.kind == "UNLOCK":
            for k in range(len(held) - 1, -1, -1):
                if held[k][0] == op.target:
                    held.pop(k)
                    break
    return edges


def find_deadlock_cycles(model: VisModel) -> List[List[Dict[str, Any]]]:
    edges = [e for t in worker_threads(model) for e in _lock_edges(t)]
    cycles: List[List[Dict[str, Any]]] = []
    seen = set()

    def dfs(path: List[Dict[str, Any]]):
        last = path[-1]
        for e in edges:
            if e["held"] != last["wants"]:
                continue
            if e["thread"] in {p["thread"] for p in path}:
                continue
            if e["wants"] == path[0]["held"]:
                cyc = path + [e]
                key = frozenset((c["thread"], c["held"], c["wants"]) for c in cyc)
                if key not in seen:
                    seen.add(key)
                    cycles.append(cyc)
                continue
            if len(path) < 4 and e["wants"] not in {p["held"] for p in path}:
                dfs(path + [e])

    for e in edges:
        dfs([e])
    return cycles


def _deadlock_schedule(model: VisModel, cycle: List[Dict[str, Any]]):
    workers = {t.id: t for t in worker_threads(model)}
    involved = [workers[e["thread"]] for e in cycle]
    eng = Engine(involved, _initial(model))
    for e in cycle:
        if not eng.run_until(e["thread"], e["heldIdx"]):
            return None
    for e in cycle:
        if e["wantsIdx"] - 1 >= eng.pc[e["thread"]] and not eng.run_until(e["thread"], e["wantsIdx"] - 1):
            return None
    blocked_steps = []
    for e in cycle:
        if eng.blocked(e["thread"]):
            blocked_steps.append(eng.attempt_blocked(e["thread"]))
    if len(blocked_steps) != len(cycle):
        return None
    for e in cycle:
        for s in eng.steps:
            if s["thread"] == e["thread"] and s["opIndex"] == e["heldIdx"] and s["kind"] == "LOCK":
                s["hazard"] = True
    for s in blocked_steps:
        s["hazard"] = True
    return {
        "kind": "DEADLOCK",
        "steps": eng.steps,
        "finalValues": eng.final_values(),
        "deadlocked": True,
        "threads": [e["thread"] for e in cycle],
        "locks": [e["held"] for e in cycle],
    }


def _order_hint(model: VisModel) -> str:
    seen: List[str] = []
    for t in worker_threads(model):
        for o in t.ops:
            if o.kind == "LOCK" and o.target not in seen:
                seen.append(o.target)
    return " -> ".join(seen)


# --------------------------------------------------------------- public

def simulate(model: VisModel, mode: str = "auto") -> Dict[str, Any]:
    """Return {schedules, hazards, notes, fixSuggestion}."""
    notes: List[str] = []
    workers = worker_threads(model)
    if not workers:
        return {"schedules": [], "hazards": [], "notes": ["No worker thread operations to simulate."], "fixSuggestion": None}

    safe = safe_schedule(model)
    expected = safe["finalValues"]
    schedules: List[Dict[str, Any]] = []
    hazards: List[Dict[str, Any]] = []
    fixes: List[str] = []

    want_race = mode in ("auto", "race")
    want_dead = mode in ("auto", "deadlock")
    want_safe = mode in ("auto", "safe")

    race_found = deadlock_found = False
    if want_race:
        for race in find_races(model):
            sched = _race_schedule(model, race, expected)
            var = race["var"]
            if sched is None:
                hazards.append(
                    {
                        "type": "DATA_RACE",
                        "variables": [var],
                        "threads": [race["a"], race["b"]],
                        "steps": [],
                        "explanation": (
                            f"Threads {race['a']} and {race['b']} access '{var}' without holding a common lock, "
                            "and at least one of the accesses is a write."
                        ),
                        "fixSuggestion": f"Guard every access to '{var}' with the same lock (synchronized) or use an atomic type.",
                    }
                )
                race_found = True
                continue
            if any(h.get("variables") == [var] and h["type"] == "RACE_CONDITION" for h in hazards):
                continue
            actual = sched["finalValues"].get(var)
            exp = expected.get(var)
            hz_steps = [s["index"] for s in sched["steps"] if s["hazard"]]
            lost = actual != exp
            sched["expected"] = {var: exp}
            sched["actual"] = {var: actual}
            schedules.append(sched)
            hazards.append(
                {
                    "type": "RACE_CONDITION",
                    "variables": [var],
                    "threads": sched["threads"],
                    "schedule": "RACE",
                    "steps": hz_steps,
                    "expected": exp,
                    "actual": actual,
                    "explanation": (
                        f"Both threads read '{var}' before either writes it back, so one update overwrites the other "
                        f"(lost update): expected {exp}, got {actual}."
                        if lost
                        else f"Threads {sched['threads'][0]} and {sched['threads'][1]} update '{var}' without a common lock; "
                        f"this interleaving happened to give {actual}, but the read-modify-write is not atomic."
                    ),
                    "fixSuggestion": (
                        f"Make the read-modify-write on '{var}' atomic: wrap it in synchronized (same lock in every thread), "
                        f"use a ReentrantLock, or switch '{var}' to AtomicInteger."
                    ),
                }
            )
            fixes.append(hazards[-1]["fixSuggestion"])
            race_found = True
            break  # one demonstrated race schedule is enough
    if want_dead:
        for cyc in find_deadlock_cycles(model):
            sched = _deadlock_schedule(model, cyc)
            if sched is None:
                continue
            schedules.append(sched)
            locks = sorted({e["held"] for e in cyc})
            thr = [e["thread"] for e in cyc]
            order = _order_hint(model)
            hazards.append(
                {
                    "type": "DEADLOCK",
                    "locks": locks,
                    "threads": thr,
                    "schedule": "DEADLOCK",
                    "steps": [s["index"] for s in sched["steps"] if s["hazard"]],
                    "explanation": (
                        "Lock acquisition order forms a cycle: "
                        + "; ".join(f"{e['thread']} holds {e['held']} and waits for {e['wants']}" for e in cyc)
                        + ". Each thread waits forever for a lock the other holds."
                    ),
                    "fixSuggestion": (
                        f"Acquire locks in one consistent global order in every thread (for example {order}), "
                        "or use tryLock with a timeout."
                    ),
                }
            )
            fixes.append(hazards[-1]["fixSuggestion"])
            deadlock_found = True
            break

    if want_safe or (not race_found and not deadlock_found):
        schedules.insert(0, safe)
    if mode == "race" and not race_found:
        notes.append("No race condition detected: every conflicting access shares a common lock (or there is no shared write).")
    if mode == "deadlock" and not deadlock_found:
        notes.append("No lock-order cycle detected, so no deadlock is possible from the recognised locks.")
    if not hazards:
        notes.append("No concurrency hazards detected in the recognised operations.")
    notes.extend(safe.get("notes", []))
    return {
        "schedules": schedules,
        "hazards": hazards,
        "notes": notes,
        "fixSuggestion": " ".join(dict.fromkeys(fixes)) or None,
    }
