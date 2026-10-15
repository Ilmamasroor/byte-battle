#!/usr/bin/env python3
"""End-to-end smoke test: Spring backend + Python AI service + Judge0, as a real learner would use them.

Needs only the Python standard library. Start PostgreSQL, Judge0, the AI service and the backend first
(see docs/running-locally.md), then:

    python3 scripts/e2e_smoke.py [--base http://localhost:8080]

Exit code 0 = every check passed. Uses a fresh throwaway account on each run.
"""
import argparse
import json
import sys
import time
import urllib.error
import urllib.request
import uuid

RACE_CONDITIONS = "00000000-0000-0000-0000-000000001003"   # seeded concept
THREADS_101_BATTLE = "00000000-0000-0000-0000-00000b000001"
PARALLEL_SUM = "00000000-0000-0000-0000-00000c000001"       # seeded coding challenge (Java)
VANISHING_INCREMENTS = "00000000-0000-0000-0000-00000d000001"  # seeded debug exercise

failures = []


def check(name, ok, detail=""):
    print(("  PASS " if ok else "  FAIL ") + name + (f"  [{detail}]" if detail else ""))
    if not ok:
        failures.append(name)


class Api:
    def __init__(self, base):
        self.base, self.token = base.rstrip("/"), None

    def call(self, method, path, body=None, timeout=180):
        data = json.dumps(body).encode() if body is not None else None
        req = urllib.request.Request(self.base + path, data=data, method=method)
        req.add_header("Content-Type", "application/json")
        if self.token:
            req.add_header("Authorization", "Bearer " + self.token)
        try:
            with urllib.request.urlopen(req, timeout=timeout) as r:
                raw = r.read().decode()
                return r.status, (json.loads(raw) if raw else None)
        except urllib.error.HTTPError as e:
            raw = e.read().decode()
            try:
                return e.code, json.loads(raw)
            except ValueError:
                return e.code, raw


def data(body):
    """Unwrap the {success, data} envelope that auth/user/Byte DNA endpoints use."""
    return body["data"] if isinstance(body, dict) and "data" in body else body


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--base", default="http://localhost:8080")
    api = Api(ap.parse_args().base)

    print("Registration + onboarding")
    email = f"smoke-{uuid.uuid4().hex[:8]}@bb.test"
    s, r = api.call("POST", "/api/auth/register", {"email": email, "password": "Passw0rd!123", "username": "smoke"})
    check("register", s == 200 and data(r).get("token"), s)
    check("registration reports onboarding as not done", data(r).get("onboardingCompleted") is False)
    api.token = data(r)["token"]
    s, r = api.call("POST", f"/api/ai/explanation?conceptId={RACE_CONDITIONS}")
    check("learning endpoints are blocked until onboarding", s == 403 and "ONBOARDING_REQUIRED" in json.dumps(r), s)
    s, qs = api.call("GET", "/api/onboarding/questions")
    ids = [q["id"] for q in qs] if s == 200 else []
    check("onboarding questions are served", {"technicalExperience", "learningStyle", "explanationStyle", "interests"} <= set(ids), ids)
    s, r = api.call("POST", "/api/onboarding", {"technicalExperience": "BEGINNER", "preferredLanguage": "java",
                                                 "careerGoal": "Campus placements", "learningStyle": "CONCEPTUAL_DEPTH",
                                                 "explanationStyle": "STORY", "interests": ["cricket"], "dailyGoalMinutes": 30,
                                                 "difficultyAreas": ["multithreading"]})
    check("onboarding answers become the baseline Byte DNA + profile", s == 200 and r.get("completed") is True, s)
    s, r = api.call("POST", "/api/onboarding", {"technicalExperience": "BEGINNER"})
    check("incomplete answers are rejected", s == 400, s)
    s, st = api.call("GET", "/api/onboarding/status")
    check("status is completed", s == 200 and st["completed"] is True and st["hasByteDna"] and st["hasLearnerProfile"], st)
    _, dna = api.call("GET", "/api/byte-dna")
    check("Byte DNA holds the self-assessment", data(dna).get("difficultyAreas") == ["multithreading"], data(dna).get("difficultyAreas"))
    s, r = api.call("POST", "/api/auth/login", {"email": email, "password": "Passw0rd!123"})
    check("login now reports onboarding done", data(r).get("onboardingCompleted") is True)

    print("Visualization")
    racy = ("public class Main { static int count = 0; public static void main(String[] a) throws Exception {"
            " Thread t1 = new Thread(() -> { for (int i = 0; i < 3; i++) count++; });"
            " Thread t2 = new Thread(() -> { for (int i = 0; i < 3; i++) count++; });"
            " t1.start(); t2.start(); t1.join(); t2.join(); } }")
    t0 = time.time()
    s, v = api.call("POST", "/api/visualize", {"code": racy})
    first = time.time() - t0
    hazards = [h["type"] for h in v.get("hazards", [])] if s == 200 else []
    check("race condition is detected deterministically", "RACE_CONDITION" in hazards, hazards)
    check("response has animatable steps and SVG", s == 200 and v["schedules"] and v["svg"], list(v.get("svg", {})))
    t0 = time.time()
    api.call("POST", "/api/visualize", {"code": racy})
    check("repeat request is served from the cache", time.time() - t0 < max(0.5, first), f"{first:.2f}s -> {time.time() - t0:.2f}s")
    s, _ = api.call("POST", "/api/visualize", {"code": ""})
    check("empty code is rejected", s == 400, s)
    s, c = api.call("GET", f"/api/visualize/concepts/{RACE_CONDITIONS}")
    check("ready-made visualization for a concept", s == 200 and c["visualization"]["svg"], s)
    s, _ = api.call("GET", "/api/visualize/concepts/00000000-0000-0000-0000-000000000001")
    check("concept without a demo is 404", s == 404, s)

    print("AI (backend -> Python service -> LLM)")
    s, r = api.call("POST", f"/api/ai/explanation?conceptId={RACE_CONDITIONS}")
    meta = (r or {}).get("metadata", {}) if isinstance(r, dict) else {}
    check("explanation uses the real concept", meta.get("conceptName") == "Race Conditions", meta.get("conceptName"))
    check("explanation is grounded and personalized", meta.get("grounded") and meta.get("personalized"), meta.get("groundedIn"))
    check("explanation is not a fallback", isinstance(r, dict) and not r.get("fallback") and r.get("content"))
    s, r = api.call("POST", f"/api/ai/analogy?conceptId={RACE_CONDITIONS}")
    check("analogy", s == 200 and r.get("analogy") and not r.get("fallback"), s)
    s, r = api.call("POST", f"/api/ai/mnemonic?conceptId={RACE_CONDITIONS}")
    check("mnemonic", s == 200 and r.get("mnemonic") and not r.get("fallback"), s)

    print("Learning stages")
    s, p = api.call("POST", "/api/learning/start", {"conceptId": "00000000-0000-0000-0000-000000001011"})
    check("start learning", s == 201 and p["currentStage"] == "UNDERSTAND", s)
    for _ in range(4):
        s, p = api.call("POST", "/api/learning/complete-stage", {"progressId": p["id"]})
    check("content stages reach BATTLE", p["currentStage"] == "BATTLE", p.get("currentStage"))
    s, _ = api.call("POST", "/api/learning/complete-stage", {"progressId": p["id"]})
    check("battle stage cannot be skipped by hand", s == 409, s)

    print("Battle")
    s, sess = api.call("POST", f"/api/battles/{THREADS_101_BATTLE}/start")
    check("start battle", s == 201 and sess.get("sessionId"), s)
    q = sess["firstQuestion"]
    s, r = api.call("POST", f"/api/battle-sessions/{sess['sessionId']}/attempts",
                    {"battleQuestionId": q["id"], "answer": "definitely-not-an-option", "timeTakenSeconds": 3})
    check("answer is graded server-side", s == 200 and r["correct"] is False and r["remainingLives"] == 2, s)
    s, _ = api.call("POST", f"/api/battle-sessions/{sess['sessionId']}/attempts",
                    {"battleQuestionId": q["id"], "answer": "again", "timeTakenSeconds": 3})
    check("answering twice is a 409", s == 409, s)
    s, r = api.call("POST", f"/api/battle-sessions/{sess['sessionId']}/complete")
    check("completing early is not a win", s == 200 and r["won"] is False, s)

    print("Coding (Judge0)")
    s, ch = api.call("GET", f"/api/coding/challenges/{PARALLEL_SUM}")
    starter = ch["starterCode"]
    fixed = (starter.replace("long[] partial = new long[threads];", "long[] partial = new long[threads];\n        Thread[] ths = new Thread[threads];")
             .replace("new Thread(() -> {", "ths[id] = new Thread(() -> {").replace("}).start();", "});\n            ths[id].start();")
             .replace("long total = 0;", "for (Thread th : ths) th.join();\n        long total = 0;"))
    t0 = time.time()
    s, bad = api.call("POST", f"/api/coding/challenges/{PARALLEL_SUM}/submissions", {"sourceCode": starter, "language": "JAVA"})
    check("buggy code is judged FAILED by the sandbox", s == 200 and bad["status"] == "FAILED", f"{s} {bad.get('status') if isinstance(bad, dict) else bad}")
    s, good = api.call("POST", f"/api/coding/challenges/{PARALLEL_SUM}/submissions", {"sourceCode": fixed, "language": "JAVA"})
    check("fixed code PASSES every test case", s == 200 and good["status"] == "PASSED", f"{s} {time.time() - t0:.0f}s")
    time.sleep(15)  # async AI feedback
    if s == 200 and isinstance(bad, dict) and bad.get("submissionId"):
        _, sub = api.call("GET", f"/api/coding/submissions/{bad['submissionId']}")
        check("AI feedback is attached to the failed submission", bool(sub.get("aiFeedback")))

    print("Debugging")
    s, ex = api.call("GET", f"/api/debugging/exercises/{VANISHING_INCREMENTS}")
    s, r = api.call("POST", f"/api/debugging/exercises/{VANISHING_INCREMENTS}/attempts", {"code": ex["buggyCode"], "timeSpentSeconds": 30})
    check("buggy exercise fails its tests", s == 200 and r["passed"] is False and r["nextAction"] == "RETRY", s)

    print("AI interview")
    s, iv = api.call("POST", "/api/interviews", {"conceptId": RACE_CONDITIONS, "difficulty": "MEDIUM"})
    check("start interview", s == 201, s)
    _, msgs = api.call("GET", f"/api/interviews/{iv['id']}/messages")
    check("first question comes from the AI, not a stub", msgs and "[stub" not in msgs[0]["content"], msgs[0]["content"][:60] if msgs else "")
    s, reply = api.call("POST", f"/api/interviews/{iv['id']}/messages", {"content":
        "A race condition is when threads read and write shared mutable state without synchronization so the "
        "result depends on scheduling. counter++ loses updates; use synchronized, locks or AtomicInteger."})
    check("answer is rubric-graded", s == 201 and reply.get("score") is not None and reply.get("feedback"), s)
    s, res = api.call("POST", f"/api/interviews/{iv['id']}/complete")
    check("interview completes with a score", s == 200 and res["status"] == "COMPLETED" and res["score"] is not None, s)

    print("Evidence -> XP / performance / Byte DNA")
    _, g = api.call("GET", "/api/gamification/me")
    check("XP and streak were awarded", g["xp"] > 0 and g["streakDays"] >= 1, g)
    _, perf = api.call("GET", "/api/performance/summary")
    check("performance evidence was recorded", perf["totalActivities"] >= 4, perf["totalActivities"])
    time.sleep(10)
    _, dna = api.call("GET", "/api/byte-dna")
    check("Byte DNA evolved from the evidence", bool(data(dna).get("topicAccuracy")), data(dna).get("topicAccuracy"))

    print()
    if failures:
        print(f"{len(failures)} check(s) FAILED: " + ", ".join(failures))
        sys.exit(1)
    print("All checks passed.")


if __name__ == "__main__":
    main()
