# Sample data and test cases

Everything below is loaded automatically: Flyway seeds the database on the first backend start (migrations V22 and V27-V29), and the AI service loads its content index at startup. No manual import is needed.

## Seeded data (PostgreSQL)

| Data | Count | Migration | Notes |
|---|---|---|---|
| Curriculum domains | 7 | V22, V27 | Java, DSA, DBMS & SQL, OS, Networks, System Design, Technical Interview Prep |
| Topics / concepts | 27 / 58 | V22, V27 | The flagship is Multithreading & Concurrency (threads, shared resources, race conditions, synchronization, locks, deadlocks) |
| Battles | 7 | V28 | Threads 101, Shared Resources Showdown, Race Condition Survival, Lock Down, Deadlock Dungeon, Synchronization Speed Round, and the boss battle "The Concurrency Colossus" (8 questions) |
| Battle questions | 38 | V28 | MCQ, predict-the-output and choose-the-approach; the answer key is server-side only |
| Coding challenges (Java) | 10 | V28 | e.g. Parallel Sum with Threads, Thread-Safe Counter, Bounded Buffer, Deadlock-Free Transfers, Binary Search Index, Maximum Subarray Sum |
| Debugging exercises | 6 | V29 | Race condition, check-then-act, wrong lock object, lock ordering, missing notify, join inside lock |

Each coding challenge ships starter code and 5+ test cases as JSON (`input`, `expectedOutput`, `hidden`). Hidden cases are never returned by the API; learners see only the sample cases. Example (Binary Search Index):

```json
[{"input":"6\n1 3 5 7 9 11\n7\n","expectedOutput":"3\n","hidden":false},
 {"input":"4\n2 4 6 8\n5\n","expectedOutput":"-1\n","hidden":false},
 {"input":"1\n10\n10\n","expectedOutput":"0\n","hidden":true}]
```

Some starter codes contain a deliberate concurrency bug (for example Parallel Sum forgets `join()`), so the hidden cases fail on the starter and pass on the fix. `scripts/e2e_smoke.py` relies on exactly that.

## AI service content (`ai-service/content/parsed/`)

Curated reference material used to ground explanations, questions and rubrics: 3,550 interview questions, plus multithreading practice and debugging problems and Java concept notes (3,613 entries indexed at startup). `ai-service/training/data/synthetic_performance_data.csv` is the synthetic data the diagnosis models were trained on (`ai-service/models_store/*.pkl`).

## Test cases

| Suite | Command | What it covers |
|---|---|---|
| Backend (179 tests) | `./mvnw -o clean test` | services, security rules, the onboarding guard, battle grading and evidence, interview scoring, Judge0 client, AI clients and fallbacks, visualization cache. H2, no external services |
| AI service (64 tests) | `cd ai-service && python -m pytest -q` | routes, prompt-safety hardening, visualizer, rubric scoring. The LLM is mocked |
| End to end | `python3 scripts/e2e_smoke.py` | 41 checks against the running stack: onboarding, the 403 guard, AI, learning stages, battle, Judge0 pass/fail, debugging, AI interview, XP, Byte DNA, visualization |

## Example requests

```bash
BASE=http://localhost:8080
TOKEN=$(curl -s -X POST $BASE/api/auth/register -H 'Content-Type: application/json' \
  -d '{"email":"demo@example.com","password":"Passw0rd!123","username":"demo"}' | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['token'])")
AUTH="Authorization: Bearer $TOKEN"

# onboarding (required before the learning endpoints)
curl -s $BASE/api/onboarding/questions -H "$AUTH"
curl -s -X POST $BASE/api/onboarding -H "$AUTH" -H 'Content-Type: application/json' -d '{
  "technicalExperience":"BEGINNER","preferredLanguage":"JAVA","careerGoal":"Campus placements",
  "learningStyle":"CONCEPTUAL_DEPTH","explanationStyle":"STORY","interests":["cricket"],
  "dailyGoalMinutes":30,"difficultyAreas":["multithreading"]}'

# personalized AI explanation of the seeded concept "Race Conditions"
curl -s -X POST "$BASE/api/ai/explanation?conceptId=00000000-0000-0000-0000-000000001003" -H "$AUTH"

# run Java in the sandbox against the seeded challenge "Parallel Sum with Threads"
curl -s $BASE/api/coding/challenges/00000000-0000-0000-0000-00000c000001 -H "$AUTH"      # starter code + sample cases
curl -s -X POST $BASE/api/coding/challenges/00000000-0000-0000-0000-00000c000001/submissions \
  -H "$AUTH" -H 'Content-Type: application/json' -d '{"sourceCode":"<your Java>","language":"JAVA"}'

# race-condition visualization of a concept
curl -s $BASE/api/visualize/concepts/00000000-0000-0000-0000-000000001003 -H "$AUTH"
```
