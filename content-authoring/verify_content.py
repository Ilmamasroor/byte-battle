#!/usr/bin/env python3
"""Verify a concept content file against the real Judge0 sandbox and write verified/<same name>.

Usage: verify_content.py content/<conceptId>.json [--no-run]   (exit 0 = VERIFIED)
"""
import base64, json, os, re, sys, time, urllib.request, urllib.error, concurrent.futures as cf

HERE = os.path.dirname(os.path.abspath(__file__))
JUDGE0 = "http://localhost:2358"
ENV = os.path.join(HERE, "..", "..", "judge0-v1.13.1", ".env")
TOKEN = ""
for line in open(ENV):
    if line.startswith("JUDGE0_AUTHN_TOKEN="): TOKEN = line.strip().split("=", 1)[1]

COMPILER_OPTS = "-J-Xshare:auto -J-XX:TieredStopAtLevel=1 -J-XX:+UseSerialGC -J-Xss512k"

def run(code, stdin="", timeout=90):
    body = json.dumps({"language_id": 62, "compiler_options": COMPILER_OPTS, "source_code": base64.b64encode(code.encode()).decode(),
                       "stdin": base64.b64encode(stdin.encode()).decode(),
                       "cpu_time_limit": 5, "wall_time_limit": 15, "memory_limit": 262144}).encode()
    req = urllib.request.Request(f"{JUDGE0}/submissions?base64_encoded=true&wait=true", data=body, method="POST",
                                 headers={"Content-Type": "application/json", "X-Auth-Token": TOKEN})
    for attempt in range(4):
        try:
            with urllib.request.urlopen(req, timeout=timeout) as r: d = json.load(r)
            dec = lambda k: base64.b64decode(d[k]).decode(errors="replace") if d.get(k) else ""
            res = {"status": d["status"]["id"], "desc": d["status"]["description"], "out": dec("stdout"), "err": dec("stderr") or dec("compile_output")}
            if res["status"] == 6 and "time limit" in res["err"].lower():
                time.sleep(3); err = "compile time limit"; continue
            return res
        except Exception as e:
            err = str(e); time.sleep(2)
    return {"status": -1, "desc": "judge0 error", "out": "", "err": err}

def norm(s): return "\n".join(l.rstrip() for l in s.replace("\r", "").rstrip("\n").split("\n")) + "\n"

def verify(doc, execute=True):
    errs, warns = [], []
    cid = doc.get("conceptId", "")
    if not re.match(r"^00000000-0000-0000-0000-0000000010(0[1-9]|[1-5][0-9])$", cid): errs.append("conceptId invalid")
    b = doc.get("battle") or {"questions": [], "_absent": True}
    if b.get("_absent") and not (doc.get("coding") or doc.get("debug")): errs.append("file has no battle, coding or debug")
    absent = b.get("_absent")
    if not absent:
        for k in ("title", "description", "battleType", "difficulty"):
            if not b.get(k): errs.append(f"battle.{k} missing")
        if b.get("battleType") not in ("QUIZ", "SURVIVAL", "SPEED_ROUND"): errs.append("battleType must be QUIZ/SURVIVAL/SPEED_ROUND")
        if b.get("difficulty") not in ("EASY", "MEDIUM", "HARD"): errs.append("battle difficulty invalid")
        if len(b.get("description", "")) > 200: errs.append("battle.description too long")
    qs = b.get("questions", [])
    if not absent and len(qs) != 5: errs.append(f"need exactly 5 questions, has {len(qs)}")
    seen, slots = set(), []
    jobs = {}
    pool = cf.ThreadPoolExecutor(max_workers=2)
    for i, q in enumerate(qs):
        w = f"Q{i + 1}"
        t = q.get("type")
        if t not in ("MCQ", "PREDICT_OUTPUT", "CHOOSE_APPROACH"): errs.append(f"{w}: bad type {t!r}")
        opts = q.get("options", [])
        if len(opts) != 4 or len(set(opts)) != 4: errs.append(f"{w}: need 4 distinct options")
        if q.get("answer") not in opts: errs.append(f"{w}: answer not among options")
        else: slots.append(opts.index(q["answer"]))
        if not q.get("explanation") or len(q["explanation"]) < 25: errs.append(f"{w}: explanation too short")
        if not q.get("text"): errs.append(f"{w}: text missing")
        ident = (q.get("text"), q.get("code"))
        if ident in seen: errs.append(f"{w}: duplicate question")
        seen.add(ident)
        for o in opts:
            if len(o) > 110: errs.append(f"{w}: option too long")
        txt = " ".join([q.get("text", ""), q.get("explanation", "")] + opts)
        if re.search(r"[—–→←•]|\*\*", txt): errs.append(f"{w}: no em dashes / unicode arrows / markdown")
        if q.get("points", 0) not in (10, 15, 20): errs.append(f"{w}: points must be 10/15/20")
        if t == "PREDICT_OUTPUT" and q.get("code") and execute:
            jobs[i] = (pool.submit(run, q["code"]), pool.submit(run, q["code"]))
        elif t == "PREDICT_OUTPUT" and q.get("code") is None:
            warns.append(f"{w}: PREDICT_OUTPUT without code (hand-checked): make sure it is right")
    if slots and max(slots.count(s) for s in set(slots)) > 2: errs.append("correct answer sits in the same slot more than twice")
    for i, (a, bb) in jobs.items():
        r1, r2 = a.result(), bb.result()
        q = qs[i]
        if r1["status"] != 3: errs.append(f"Q{i + 1}: program failed ({r1['desc']}): {r1['err'][:200]}"); continue
        if r1["out"] != r2["out"]: errs.append(f"Q{i + 1}: program is non-deterministic"); continue
        got = " / ".join(l.rstrip() for l in r1["out"].replace("\r", "").rstrip("\n").split("\n"))
        if got != q["answer"]: errs.append(f"Q{i + 1}: program prints {got!r} but answer is {q['answer']!r}")
        if len(q["code"].splitlines()) > 30: errs.append(f"Q{i + 1}: program too long")

    for i, c in enumerate(doc.get("coding", [])):
        w = f"coding[{i}] {c.get('title')}"
        for k in ("title", "description", "difficulty", "inputDescription", "outputDescription", "constraints", "starterCode", "solutionCode"):
            if not c.get(k): errs.append(f"{w}: {k} missing")
        tests = c.get("tests", [])
        if not 6 <= len(tests) <= 9: errs.append(f"{w}: need 6-9 tests"); continue
        if sum(1 for t in tests if not t.get("hidden")) < 2: errs.append(f"{w}: first two tests must be visible")
        if not execute: continue
        sol = [(t, pool.submit(run, c["solutionCode"], t["input"]), pool.submit(run, c["solutionCode"], t["input"])) for t in tests]
        sta = [pool.submit(run, c["starterCode"], t["input"]) for t in tests]
        failed_starter = 0
        for (t, a, bb), st in zip(sol, sta):
            r1, r2 = a.result(), bb.result()
            if r1["status"] != 3: errs.append(f"{w}: solution failed on {t['input'][:30]!r}: {r1['desc']} {r1['err'][:160]}"); continue
            if r1["out"] != r2["out"]: errs.append(f"{w}: solution non-deterministic")
            t["expectedOutput"] = norm(r1["out"])
            if not t["expectedOutput"].strip(): errs.append(f"{w}: empty expected output")
            rs = st.result()
            if rs["status"] == 6: errs.append(f"{w}: starterCode does not compile: {rs['err'][:160]}")
            if rs["status"] != 3 or norm(rs["out"]) != t["expectedOutput"]: failed_starter += 1
        if failed_starter == 0: errs.append(f"{w}: starterCode already passes every test")
        outs = {t.get("expectedOutput") for t in tests}
        if len(outs) < 3: warns.append(f"{w}: very few distinct expected outputs")

    for i, d in enumerate(doc.get("debug", [])):
        w = f"debug[{i}] {d.get('title')}"
        for k in ("title", "description", "difficulty", "bugCategory", "buggyCode", "solutionCode"):
            if not d.get(k): errs.append(f"{w}: {k} missing")
        if len(d.get("hints", [])) != 4: errs.append(f"{w}: exactly 4 hints")
        tests = d.get("tests", [])
        if not 4 <= len(tests) <= 6: errs.append(f"{w}: need 4-6 tests"); continue
        if not execute: continue
        sol = [(t, pool.submit(run, d["solutionCode"], t["input"]), pool.submit(run, d["solutionCode"], t["input"])) for t in tests]
        bug = [pool.submit(run, d["buggyCode"], t["input"]) for t in tests]
        buggy_fail = 0
        for (t, a, bb), bg in zip(sol, bug):
            r1, r2 = a.result(), bb.result()
            if r1["status"] != 3: errs.append(f"{w}: solution failed: {r1['desc']} {r1['err'][:160]}"); continue
            if r1["out"] != r2["out"]: errs.append(f"{w}: solution non-deterministic")
            t["expectedOutput"] = norm(r1["out"])
            rb = bg.result()
            if rb["status"] == 6: errs.append(f"{w}: buggyCode does not compile: {rb['err'][:160]}")
            elif rb["status"] != 3 or norm(rb["out"]) != t["expectedOutput"]: buggy_fail += 1
        if buggy_fail == 0: errs.append(f"{w}: buggyCode passes every test, so there is no visible bug")
    pool.shutdown()
    return errs, warns, doc

def main():
    path = sys.argv[1]
    execute = "--no-run" not in sys.argv
    doc = json.load(open(path))
    errs, warns, doc = verify(doc, execute)
    for w in warns: print("  warn:", w)
    if errs:
        print(f"FAIL {os.path.basename(path)}")
        for e in errs: print("  -", e)
        return 1
    if not execute:
        print(f"CHECKED (not executed, nothing written) {os.path.basename(path)}"); return 0
    out = os.path.join(HERE, "verified"); os.makedirs(out, exist_ok=True)
    json.dump(doc, open(os.path.join(out, os.path.basename(path)), "w"), indent=1)
    print(f"VERIFIED {os.path.basename(path)}")
    return 0

if __name__ == "__main__":
    sys.exit(main())
