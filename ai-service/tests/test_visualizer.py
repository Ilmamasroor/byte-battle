"""Visualization engine tests using real Java snippets. Fully offline."""
import xml.etree.ElementTree as ET

import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.services import ai_service
from app.services.visualizer.extractor import extract_deterministic
from app.services.visualizer.flow import build_flow
from app.services.visualizer.service import visualize

RACY = """public class Counter {
    private int count = 0;

    public void increment() {
        count++;
    }

    public static void main(String[] args) throws Exception {
        Counter c = new Counter();
        Thread t1 = new Thread(() -> { c.increment(); });
        Thread t2 = new Thread(() -> { c.increment(); });
        t1.start(); t2.start();
        t1.join(); t2.join();
        System.out.println(c.count);
    }
}
"""

SYNC_FIXED = """public class SafeCounter {
    private int count = 0;

    public synchronized void increment() {
        count++;
    }

    public static void main(String[] args) throws Exception {
        SafeCounter c = new SafeCounter();
        Thread t1 = new Thread(() -> c.increment());
        Thread t2 = new Thread(() -> c.increment());
        t1.start(); t2.start();
        t1.join(); t2.join();
    }
}
"""

SYNC_BLOCK = """public class Counter {
    private int count = 0;
    private final Object lock = new Object();

    public void increment() {
        synchronized (lock) {
            count = count + 1;
        }
    }

    public static void main(String[] args) {
        Counter c = new Counter();
        new Thread(() -> c.increment()).start();
        new Thread(() -> c.increment()).start();
    }
}
"""

DIFFERENT_LOCKS = """public class Bad {
    static int total = 0;
    static final Object a = new Object();
    static final Object b = new Object();
    public static void main(String[] args) {
        Thread t1 = new Thread(() -> { synchronized (a) { total += 5; } });
        Thread t2 = new Thread(() -> { synchronized (b) { total += 5; } });
        t1.start(); t2.start();
    }
}
"""

DEADLOCK = """public class Deadlock {
    private static final Object lockA = new Object();
    private static final Object lockB = new Object();

    public static void main(String[] args) {
        Thread t1 = new Thread(() -> {
            synchronized (lockA) {
                try { Thread.sleep(50); } catch (InterruptedException e) {}
                synchronized (lockB) {
                    System.out.println("t1 got both");
                }
            }
        });
        Thread t2 = new Thread(() -> {
            synchronized (lockB) {
                synchronized (lockA) {
                    System.out.println("t2 got both");
                }
            }
        });
        t1.start();
        t2.start();
    }
}
"""

REENTRANT_DEADLOCK = """import java.util.concurrent.locks.ReentrantLock;

public class Bank {
    private final ReentrantLock lockA = new ReentrantLock();
    private final ReentrantLock lockB = new ReentrantLock();
    private int balance = 100;

    void transferAB() {
        lockA.lock();
        try {
            lockB.lock();
            try { balance -= 10; } finally { lockB.unlock(); }
        } finally { lockA.unlock(); }
    }

    void transferBA() {
        lockB.lock();
        try {
            lockA.lock();
            try { balance += 10; } finally { lockA.unlock(); }
        } finally { lockB.unlock(); }
    }

    public static void main(String[] args) {
        Bank bank = new Bank();
        Thread t1 = new Thread(bank::transferAB, "alice");
        Thread t2 = new Thread(bank::transferBA, "bob");
        t1.start(); t2.start();
    }
}
"""

REENTRANT_ORDERED = REENTRANT_DEADLOCK.replace(
    "lockB.lock();\n        try {\n            lockA.lock();\n            try { balance += 10; } finally { lockA.unlock(); }\n        } finally { lockB.unlock(); }",
    "lockA.lock();\n        try {\n            lockB.lock();\n            try { balance += 10; } finally { lockB.unlock(); }\n        } finally { lockA.unlock(); }",
)

THREAD_SUBCLASS = """class Worker extends Thread {
    static int total = 10;
    public void run() {
        total += 5;
    }
}
public class Main {
    public static void main(String[] a) {
        Worker w1 = new Worker();
        Worker w2 = new Worker();
        w1.start(); w2.start();
    }
}
"""

EXECUTOR = """import java.util.concurrent.*;
public class Ex {
    static int hits = 0;
    public static void main(String[] args) {
        ExecutorService ex = Executors.newFixedThreadPool(2);
        ex.submit(() -> { hits++; });
        ex.submit(() -> { hits++; });
        ex.shutdown();
    }
}
"""

NO_THREADS = """public class Hello {
    public static void main(String[] args) {
        int sum = 0;
        for (int i = 0; i < 10; i++) { sum += i; }
        System.out.println(sum);
    }
}
"""


def parse_svg(svg: str) -> ET.Element:
    root = ET.fromstring(svg)
    assert root.tag.endswith("svg")
    assert root.get("width") and root.get("height") and root.get("viewBox")
    return root


def svg_text(svg: str) -> str:
    return " ".join("".join(el.itertext()) for el in parse_svg(svg).iter())


def ops(model, tid):
    t = next(t for t in model["threads"] if t["id"] == tid)
    return [(o["kind"], o["target"], o["line"]) for o in t["ops"]]


# ---------------------------------------------------------------- extractor

def test_extractor_expands_increment_through_method_call():
    model = extract_deterministic(RACY)
    ids = [t.id for t in model.threads]
    assert ids == ["main", "t1", "t2"]
    t1 = next(t for t in model.threads if t.id == "t1")
    assert [(o.kind, o.target, o.line) for o in t1.ops] == [("READ", "count", 5), ("WRITE", "count", 5)]
    assert [(s.name, s.initial) for s in model.shared] == [("count", 0)]
    main = next(t for t in model.threads if t.id == "main")
    assert [o.kind for o in main.ops[:4]] == ["START", "START", "JOIN", "JOIN"]
    assert model.confidence == "high"


def test_extractor_synchronized_method_and_block():
    m = extract_deterministic(SYNC_FIXED)
    t1 = next(t for t in m.threads if t.id == "t1")
    assert [o.kind for o in t1.ops] == ["LOCK", "READ", "WRITE", "UNLOCK"]
    assert "c" in m.locks
    m = extract_deterministic(SYNC_BLOCK)
    t = next(t for t in m.threads if t.id == "Thread-1")
    assert [(o.kind, o.target) for o in t.ops] == [("LOCK", "lock"), ("READ", "count"), ("WRITE", "count"), ("UNLOCK", "lock")]
    assert t.ops[1].line == 7  # count = count + 1 -> READ then WRITE


def test_extractor_reentrantlock_wait_notify_sleep():
    m = extract_deterministic(REENTRANT_DEADLOCK)
    alice = next(t for t in m.threads if t.id == "alice")
    kinds = [(o.kind, o.target) for o in alice.ops]
    assert kinds[:2] == [("LOCK", "lockA"), ("LOCK", "lockB")]
    assert ("WRITE", "balance") in kinds and kinds[-2:] == [("UNLOCK", "lockB"), ("UNLOCK", "lockA")]
    src = """class Q {
        int items = 0;
        final Object mon = new Object();
        void put() throws Exception {
            synchronized (mon) { items++; mon.notifyAll(); }
        }
        void take() throws Exception {
            synchronized (mon) { mon.wait(); Thread.sleep(10); items--; }
        }
        public static void main(String[] a) {
            Q q = new Q();
            new Thread(() -> { try { q.take(); } catch (Exception e) {} }).start();
            new Thread(() -> { try { q.put(); } catch (Exception e) {} }).start();
        }
    }"""
    m = extract_deterministic(src)
    kinds = {o.kind for t in m.threads for o in t.ops}
    assert {"WAIT", "NOTIFY", "SLEEP", "LOCK", "UNLOCK", "READ", "WRITE"} <= kinds


def test_extractor_thread_subclass_executor_and_compound_assignment():
    m = extract_deterministic(THREAD_SUBCLASS)
    assert [t.id for t in m.threads if t.id != "main"] == ["w1", "w2"]
    w1 = next(t for t in m.threads if t.id == "w1")
    assert w1.ops[1].kind == "WRITE" and w1.ops[1].delta == 5
    m = extract_deterministic(EXECUTOR)
    workers = [t for t in m.threads if t.id != "main"]
    assert len(workers) == 2 and all([o.kind for o in t.ops] == ["READ", "WRITE"] for t in workers)


def test_extractor_no_threads():
    m = extract_deterministic(NO_THREADS)
    assert m.threads == [] and m.confidence == "low"


# ---------------------------------------------------------------- simulator / service

def test_racy_counter_lost_update():
    r = visualize(RACY, use_llm=False)
    assert r["confidence"] == "high"
    kinds = [s["kind"] for s in r["schedules"]]
    assert kinds == ["SAFE", "RACE"]
    safe, race = r["schedules"]
    assert safe["finalValues"] == {"count": 2}
    assert race["finalValues"] == {"count": 1}
    # interleaving: t1 READ, t2 READ, t2 WRITE, t1 WRITE (lost update)
    assert [(s["thread"], s["kind"]) for s in race["steps"]] == [("t1", "READ"), ("t2", "READ"), ("t2", "WRITE"), ("t1", "WRITE")]
    assert [s.get("local") for s in race["steps"] if s["kind"] == "READ"] == [0, 0]
    assert [s["hazard"] for s in race["steps"]] == [True] * 4
    h = r["hazards"][0]
    assert h["type"] == "RACE_CONDITION" and h["variables"] == ["count"]
    assert h["expected"] == 2 and h["actual"] == 1 and h["steps"] == [0, 1, 2, 3]
    assert "synchronized" in r["fixSuggestion"]
    assert set(r["svg"]) == {"safe", "race"}
    text = svg_text(r["svg"]["race"])
    assert "expected 2, got 1" in text and "count=1" in text and "L5" in text and "t1" in text and "t2" in text
    assert "init 0" in text
    assert "hatch" in r["svg"]["race"]


def test_synchronized_fixed_versions_have_no_hazard():
    for code in (SYNC_FIXED, SYNC_BLOCK):
        r = visualize(code, use_llm=False)
        assert r["hazards"] == []
        assert [s["kind"] for s in r["schedules"]] == ["SAFE"]
        assert r["schedules"][0]["finalValues"] == {"count": 2}
        assert "No concurrency hazards" in " ".join(r["notes"])
        svg = r["svg"]["safe"]
        assert "LOCK" in svg_text(svg) and "UNLOCK" in svg_text(svg)


def test_different_locks_on_same_variable_is_still_a_race():
    r = visualize(DIFFERENT_LOCKS, use_llm=False)
    assert [h["type"] for h in r["hazards"]] == ["RACE_CONDITION"]
    assert r["hazards"][0]["expected"] == 10 and r["hazards"][0]["actual"] == 5


def test_two_lock_deadlock():
    r = visualize(DEADLOCK, use_llm=False)
    assert [h["type"] for h in r["hazards"]] == ["DEADLOCK"]
    h = r["hazards"][0]
    assert h["locks"] == ["lockA", "lockB"] and sorted(h["threads"]) == ["t1", "t2"]
    assert "consistent" in h["fixSuggestion"] and "lockA -> lockB" in h["fixSuggestion"]
    dead = next(s for s in r["schedules"] if s["kind"] == "DEADLOCK")
    assert dead["deadlocked"] is True
    blocked = [s for s in dead["steps"] if s.get("blocked")]
    assert sorted((s["thread"], s["target"]) for s in blocked) == [("t1", "lockB"), ("t2", "lockA")]
    assert {s["thread"]: s["waitingFor"] for s in blocked} == {"t1": "t2", "t2": "t1"}
    text = svg_text(r["svg"]["deadlock"])
    assert "DEADLOCK" in text and "BLOCKED" in text and "lockA" in text and "lockB" in text


def test_reentrantlock_deadlock_and_ordered_fix():
    r = visualize(REENTRANT_DEADLOCK, use_llm=False)
    assert [h["type"] for h in r["hazards"]] == ["DEADLOCK"]
    assert sorted(r["hazards"][0]["threads"]) == ["alice", "bob"]
    assert not any(h["type"] == "RACE_CONDITION" for h in r["hazards"])  # balance is protected by both locks
    assert "alice" in svg_text(r["svg"]["deadlock"])
    fixed = visualize(REENTRANT_ORDERED, use_llm=False)
    assert fixed["hazards"] == []


def test_mode_filters():
    assert [s["kind"] for s in visualize(RACY, mode="safe", use_llm=False)["schedules"]] == ["SAFE"]
    assert [s["kind"] for s in visualize(RACY, mode="race", use_llm=False)["schedules"]] == ["RACE"]
    r = visualize(SYNC_FIXED, mode="race", use_llm=False)
    assert [s["kind"] for s in r["schedules"]] == ["SAFE"] and any("No race" in n for n in r["notes"])
    r = visualize(RACY, mode="deadlock", use_llm=False)
    assert r["hazards"] == [] and any("No lock-order cycle" in n for n in r["notes"])


def test_thread_subclass_and_executor_races():
    r = visualize(THREAD_SUBCLASS, use_llm=False)
    assert r["hazards"][0]["expected"] == 20 and r["hazards"][0]["actual"] == 15
    r = visualize(EXECUTOR, use_llm=False)
    assert r["hazards"][0]["variables"] == ["hits"] and r["hazards"][0]["actual"] == 1


def test_no_threads_low_confidence_and_empty():
    r = visualize(NO_THREADS, use_llm=False)
    assert r["confidence"] == "low"
    assert r["model"]["threads"] == [] and r["schedules"] == [] and r["hazards"] == [] and r["svg"] == {}
    assert r["notes"]


def test_llm_extractor_fallback_is_validated(monkeypatch):
    class Fake:
        def generate_json(self, prompt, system=None):
            assert "<learner_data" in prompt and system
            return {
                "threads": [
                    {"id": "a", "label": "A", "ops": [{"kind": "READ", "target": "n", "line": 1, "text": "tmp = n"}, {"kind": "WRITE", "target": "n", "line": 1, "text": "n = tmp + 1", "delta": 1}]},
                    {"id": "b", "label": "B", "ops": [{"kind": "READ", "target": "n", "line": 2, "text": "tmp = n"}, {"kind": "WRITE", "target": "n", "line": 2, "text": "n = tmp + 1", "delta": 1}]},
                ],
                "shared": [{"name": "n", "initial": 0}],
                "locks": [],
            }

    monkeypatch.setattr(ai_service, "llm_client", Fake())
    r = visualize("void f() { someFrameworkSpawn(); }", use_llm=True)
    assert r["model"]["source"] == "llm" and r["confidence"] == "medium"
    assert r["hazards"][0]["type"] == "RACE_CONDITION" and r["hazards"][0]["actual"] == 1


def test_llm_extractor_bad_output_falls_back_low(monkeypatch):
    class Bad:
        def generate_json(self, prompt, system=None):
            return {"threads": [{"id": "a", "ops": [{"kind": "TELEPORT"}]}]}

    monkeypatch.setattr(ai_service, "llm_client", Bad())
    r = visualize("class X {}", use_llm=True)
    assert r["confidence"] == "low" and r["model"]["source"] == "fallback" and r["svg"] == {}


def test_svg_escapes_xml_in_labels():
    code = RACY.replace("Counter", "Counter").replace("count", "cnt")
    r = visualize(code, use_llm=False)
    parse_svg(r["svg"]["race"])
    from app.services.visualizer.models import Op, ThreadModel, VisModel
    from app.services.visualizer.renderer import render_schedule

    model = VisModel(threads=[ThreadModel(id="t<1>&", label="t<1>&", ops=[Op(kind="READ", target="a&b", line=1, text='x < y && "z"')])], shared=[])
    sched = {"kind": "SAFE", "steps": [{"index": 0, "thread": "t<1>&", "opIndex": 0, "kind": "READ", "target": "a&b", "line": 1, "text": 'x < y && "z"', "hazard": False, "local": 0}], "finalValues": {}}
    svg = render_schedule(model, sched)
    parse_svg(svg)
    assert "&lt;1&gt;&amp;" in svg


# ---------------------------------------------------------------- flow

FLOW = """public class Grades {
    static int grade(int s) {
        int r = 0;
        if (s > 90) { r = 4; } else if (s > 80) { r = 3; } else { r = 1; }
        for (int i = 0; i < 3; i++) {
            if (i == 1) continue;
            log(i);
        }
        while (r > 0) r--;
        return r;
    }
}
"""


def test_flow_diagram_for_teaching_snippet():
    r = build_flow(FLOW, "grade")
    kinds = [n["kind"] for n in r["nodes"]]
    assert kinds.count("if") == 3 and kinds.count("for") == 1 and kinds.count("while") == 1
    assert kinds[-1] == "return" and "call" in kinds
    labels = [n["label"] for n in r["nodes"]]
    assert "if (s > 90)" in labels and "log(i)" in labels and "return r" in labels
    assert next(n for n in r["nodes"] if n["label"] == "log(i)")["line"] == 7
    text = svg_text(r["svg"])
    assert "grade(int s)" in text and "if (s > 90)" in text and "yes" in text and "no" in text
    assert r["confidence"] == "high"


def test_flow_bare_snippet_and_empty_and_escape():
    r = build_flow("int x = 1;\nif (x < 2 && y > 3) { x++; }\nSystem.out.println(\"a<b\");")
    parse_svg(r["svg"])
    assert [n["kind"] for n in r["nodes"]] == ["stmt", "if", "stmt", "call"]
    assert "x &lt; 2 &amp;&amp; y" in r["svg"]
    r = build_flow("   ")
    assert r["confidence"] == "low" and r["nodes"] == []
    parse_svg(r["svg"])


def test_flow_do_while_and_early_return():
    code = """int f(int n) {
        do { n--; } while (n > 0);
        if (n == 0) return 1;
        return 2;
    }"""
    r = build_flow(code, "f")
    parse_svg(r["svg"])
    assert [n["kind"] for n in r["nodes"]] == ["stmt", "do", "if", "return", "return"]


# ---------------------------------------------------------------- routes

def test_visualize_routes():
    c = TestClient(app)
    r = c.post("/visualize", json={"code": RACY, "language": "java", "mode": "auto", "concept": "race condition", "useLlm": False})
    assert r.status_code == 200
    body = r.json()
    assert set(body) >= {"model", "schedules", "hazards", "svg", "notes", "confidence"}
    parse_svg(body["svg"]["race"])
    assert c.post("/visualize", json={"code": "x" * 20001}).status_code == 422
    assert c.post("/visualize", json={"code": "class A{}", "mode": "bogus"}).status_code == 422
    assert c.post("/visualize", json={"code": "class A{}", "language": "python"}).status_code == 422
    r = c.post("/visualize/flow", json={"code": FLOW, "method": "grade"})
    assert r.status_code == 200 and r.json()["method"] == "grade"
    parse_svg(r.json()["svg"])
