# Learning content schema (battles, coding challenges, debugging exercises)

One file per concept: `content-authoring/content/<conceptId>.json`. Run the verifier on it (see bottom); it runs every
program on the real Judge0 sandbox, computes expected outputs from YOUR reference solutions, and writes the verified
file to `content-authoring/verified/`. Only verified files are shipped.

```json
{
  "conceptId": "00000000-0000-0000-0000-000000001001",
  "battle": {      // OMIT the whole battle key when the brief says the concept already has a battle
    "title": "Java Fundamentals Showdown",
    "description": "One line (<= 120 chars).",
    "battleType": "QUIZ | SURVIVAL | SPEED_ROUND",
    "difficulty": "EASY | MEDIUM | HARD",
    "timeLimitSeconds": 300,
    "questions": [ { ...see below... } ]          // exactly 5
  },
  "coding":  [ { ...see below... } ],             // 0..2 (only where the topic is genuinely code-runnable in Java)
  "debug":   [ { ...see below... } ]              // 0..2 (same rule)
}
```

## Battle question (exactly 5 per concept, a mix of types, ramping easy to hard)
```json
{ "type": "MCQ | PREDICT_OUTPUT | CHOOSE_APPROACH",
  "text": "The question. For PREDICT_OUTPUT do NOT paste code here; put it in `code`.",
  "code": "public class Main { ... }",          // PREDICT_OUTPUT only: a COMPLETE runnable Java program (class Main)
  "options": ["four", "distinct", "plausible", "options"],
  "answer": "must equal one option EXACTLY",
  "explanation": "Why the answer is right AND what the tempting wrong option gets wrong (1-3 sentences).",
  "points": 10 }
```
* PREDICT_OUTPUT: the program is executed; its stdout lines joined with `" / "` must equal `answer` (verified!). Program
  must exit normally (catch exceptions and print instead of crashing), be deterministic, read no input, and be <= 25 lines.
  Use for Java / DSA / algorithm topics. For SQL topics you may use `PREDICT_OUTPUT` WITHOUT `code`: put the tables and the
  query in `text` (plain text) and the options are result summaries; you must hand-check these carefully.
* CHOOSE_APPROACH: a short scenario ("You need X. Which approach?") with 4 approaches; one clearly best and explained.
* MCQ: conceptual. Avoid trivia; test understanding and common misconceptions. Distractors must be tempting, not silly.
* Vary which position holds the correct option (no more than 2 of 5 in the same slot).
* Options <= 110 chars each. Plain ASCII, no markdown, no em dashes. Use "->" not unicode arrows.
* Questions must be about THIS concept (not its neighbours) and correct for modern Java 17 / standard CS definitions.
* Points: 10 for easy, 15 medium, 20 hard (ramp across the 5).

## Coding challenge (Java, stdin -> stdout, deterministic)
```json
{ "title": "Count Even Numbers",
  "description": "Full problem statement, 2-5 sentences, plain text.",
  "difficulty": "EASY | MEDIUM | HARD",
  "inputDescription": "Line 1: n. Line 2: n integers.",
  "outputDescription": "A single integer.",
  "constraints": "1 <= n <= 1000, |a[i]| <= 1000",
  "starterCode": "complete compilable Main with the I/O boilerplate done and a TODO where the learner writes the core logic; it must compile but be WRONG (e.g. prints 0)",
  "solutionCode": "complete correct Main",
  "tests": [ { "input": "5\n1 2 3 4 5\n", "hidden": false } ]    // 6 to 9 tests; first 2 hidden:false, the rest hidden:true
}
```
* You supply only `input`. The verifier runs `solutionCode` to produce `expectedOutput`. So your solution must be right.
* Tests must include: a sample, an edge (smallest input), a negative/zero case where relevant, and a larger case.
* Output must be unambiguous (one valid answer; sort ties deterministically). No floating point output unless rounded in code.
* Program class is `public class Main`; read with `BufferedReader` or `Scanner`.
* The starter must FAIL at least one test (verified). A learner must have to write real logic.
* Do not use threads in challenges outside concurrency topics.

## Debugging exercise (find and fix the bug)
```json
{ "title": "The Off-By-One Sum",
  "description": "What the program should do, what goes wrong; include the input format and the expected output format.",
  "difficulty": "EASY | MEDIUM | HARD",
  "bugCategory": "OFF_BY_ONE | NULL_POINTER | WRONG_CONDITION | LOGIC_ERROR | STATE_MUTATION | RESOURCE_LEAK | ... (UPPER_SNAKE)",
  "buggyCode": "complete compilable Main with ONE realistic bug (wrong output on some tests, never a compile error)",
  "solutionCode": "the same program fixed",
  "tests": [ { "input": "...", "hidden": false } ],               // 4 to 6; buggy must fail at least one
  "hints": ["nudge: what to observe", "narrower: where to look", "near-answer: what kind of mistake", "reveal: the fix in words"]  // exactly 4
}
```
* The bug must be the kind real learners make in this concept. One bug, not three.

## Rules for every concept
* Content must be accurate. When unsure, simplify the question rather than risk a wrong answer.
* No copyrighted text. Write original questions and code.
* Do not include any secrets, URLs or personal data.

## Verify
```
python3 content-authoring/verify_content.py content-authoring/content/<conceptId>.json
```
Fix every FAIL and rerun until it prints `VERIFIED`. The verifier needs the local Judge0 (already running).
