# Byte Battle

**Think Deeper. Code Better.** A free, adaptive technical-learning platform that turns *knowing* a concept into *being able to use it*: learn, practice, fail, get a diagnosis, improve, and prepare for the interview, in one connected loop.

Hack for Social Cause entry. Theme: Education & Skill Development. UN SDGs: **4** (Quality Education, target 4.4 skills for employment), **8** (Decent Work) and **10** (Reduced Inequalities).

---

## Why this exists

Learners can find content everywhere, yet many still struggle to apply a concept in code, debug it, or explain it in an interview. In our preliminary survey of 19 technical learners:

* **84.2% (16/19)** often or occasionally struggle to answer an interview question, solve a problem, or explain a concept after studying it.
* **47.4% (9/19)** rated their difficulty applying concepts at 4 or 5 out of 5.
* **63.2% (12/19)** already stitch together AI assistants, YouTube, documentation and coding sites to get unstuck.

This is a small survey, not a national study; it motivates the problem and is not a measure of impact. Learners without mentors, paid courses or interview coaching, which is common outside metro colleges, bear this gap hardest. Byte Battle is built to run on free tooling: self-hosted code execution (Judge0), a free LLM tier, the browser's or phone's own text-to-speech, and no paid cloud services. Full statement: [docs/problem-statement.md](docs/problem-statement.md).

## What it does

The loop: **Understand, Visualize, Relate, Remember, Battle, Code, Debug, Explain, Diagnose, Improve.**

* **Adaptive profile ("Byte DNA")** built at onboarding and updated from every result.
* **Visualize concepts honestly.** A deterministic simulator reads the learner's Java thread code, builds the interleavings (a lost update, a lock fixing it) and plays them as synchronized thread lanes, a timeline, a source-line highlight, captions and optional spoken narration. Each lesson is labelled a *teaching simulation* or an *authored example*, and programs it cannot model accurately are reported as unsupported, never faked. Details: [docs/visualization-platform.md](docs/visualization-platform.md).
* **Battles, coding challenges and debugging exercises**, graded by the backend and Judge0, never by the LLM.
* **Diagnosis and recommendations:** failures are analysed, the learner profile evolves, and the next step is recommended.
* **AI interview practice** with a rubric score per answer, plus XP, streaks and a readiness view.
* **Learner controls:** captions always available; narration, speed (Slower / Normal / Faster) and volume are optional.

Flagship domain: Java multithreading and concurrency (race conditions, synchronization, deadlocks), with DSA, DBMS, OS, networks, system design and interview preparation in the curriculum.

## Architecture at a glance

```
Flutter client (tested on web; mobile targets supported by Flutter)  ->  Spring Boot API (JWT, Flyway, PostgreSQL)
                                             |-> Judge0 CE (sandboxed code execution)
                                             |-> Python FastAPI AI service (grounded LLM + deterministic visualizer)
```

Diagrams and module responsibilities: [docs/architecture.md](docs/architecture.md). Use cases and user stories: [docs/use-cases.md](docs/use-cases.md), [docs/user-stories.md](docs/user-stories.md). Sample data and example requests: [docs/sample-data.md](docs/sample-data.md).

## Quick demo (web)

Follow [Quick Start](#2-quick-start) to start the services, then run the client in a browser: `cd frontend && flutter run -d web-server --web-port 5000` and open `http://localhost:5000`. Register, finish onboarding, open a concept such as **Race Conditions** and choose **Visualize**. Press play to follow the lost update step by step; switch to the lock variant to see it fixed. Narration needs a browser with speech voices (Chrome works); the caption is always shown.

## Repository layout

| Path | What it is |
|---|---|
| `src/` | Spring Boot backend (this folder's Maven project) |
| `frontend/` | Flutter client, including the visualization engine (`lib/features/learning/viz3d`) |
| `ai-service/` | Python FastAPI AI service and the deterministic thread simulator |
| `judge0/` | Judge0 sandbox (Docker Compose) |
| `docs/` | Architecture, problem statement, use cases, sample data, visualization notes |
| `scripts/` | `e2e_smoke.py`, an end-to-end walk through a learner journey |

Running it end to end: see [docs/running-locally.md](docs/running-locally.md).

---

## 1. Tech Stack

| Layer | Technology |
|---|---|
| Language / Framework | Java 17, Spring Boot 3.5.x |
| Build tool | Maven (`./mvnw`) |
| Database | PostgreSQL 16 + Flyway |
| Auth | Spring Security + JWT (jjwt), roles USER / ADMIN |
| Code execution | Judge0 CE 1.13.1 (`judge0/`) |
| AI | Python FastAPI service (`ai-service/`) |
| Testing | JUnit 5, Mockito, MockRestServiceServer, WebMvcTest |

Root package: `com.bytebattle`

---

## 2. Quick Start

Repository layout: this folder is the Spring Boot backend; `ai-service/` is the Python AI service; `judge0/` is the code-execution sandbox (Docker); `frontend/` is the Flutter client. Architecture and diagrams: [docs/architecture.md](docs/architecture.md).

**Prerequisites:** Java 17+, Docker (with Compose), Python 3.11+, a free [Groq API key](https://console.groq.com/keys) for the LLM features.

```bash
# 1. PostgreSQL for the backend (use another host port if 5432 is taken, and adjust DB_URL)
docker run -d --name bytebattle-pg -e POSTGRES_PASSWORD=devpass -e POSTGRES_DB=bytebattle_db -p 5432:5432 postgres:16.2

# 2. Judge0 (code execution). Fill the four secrets in judge0/.env first (see judge0/README.md)
cd judge0 && cp .env.example .env && docker compose up -d && cd ..

# 3. AI service on :8000 (put GROQ_API_KEY in ai-service/.env, see ai-service/.env.example)
cd ai-service && python -m venv .venv && .venv/bin/pip install -r requirements.txt
.venv/bin/python -m uvicorn app.main:app --port 8000 &      # then: curl localhost:8000/health
cd ..

# 4. Backend on :8080 (Flyway creates and seeds the schema on first start)
export SPRING_PROFILES_ACTIVE=dev DB_PASSWORD=devpass JUDGE0_AUTH_TOKEN=<JUDGE0_AUTHN_TOKEN from judge0/.env>
./mvnw spring-boot:run

# 5. Flutter client (needs the Flutter SDK; base URL is in frontend/lib/app/constants/api_endpoints.dart,
#    use http://10.0.2.2:8080 from an Android emulator)
cd frontend && flutter pub get && flutter run && cd ..

# 6. Verify the whole stack (registers a throwaway learner and walks the full loop)
python3 scripts/e2e_smoke.py
```

Tests without any external service: `./mvnw -o clean test` (backend, H2) and `cd ai-service && .venv/bin/python -m pytest -q` (AI, LLM mocked).
More detail and troubleshooting: [docs/running-locally.md](docs/running-locally.md). Sample data and example requests: [docs/sample-data.md](docs/sample-data.md).

### Environment variables

Copy `.env.example` (backend), `ai-service/.env.example` and `judge0/.env.example` to `.env` (git-ignored) and fill them in. Never commit real values.

| Component | Variable | Purpose / default |
|---|---|---|
| Backend | `SPRING_PROFILES_ACTIVE` | `dev` supplies a throwaway JWT secret and SQL logging (local only) |
| Backend | `DB_URL`, `DB_USERNAME`, `DB_PASSWORD` | Postgres (`jdbc:postgresql://localhost:5432/bytebattle_db`, `postgres`); `DB_PASSWORD` has no default |
| Backend | `JWT_SECRET`, `JWT_EXPIRATION_MS` | required outside `dev` (32+ random chars); default expiry 24 h |
| Backend | `ADMIN_BOOTSTRAP_EMAIL` | an existing user with this email is promoted to ADMIN at startup |
| Backend | `CORS_ALLOWED_ORIGINS`, `FRONTEND_URL` | allowed web origins; link base for password-reset emails |
| Backend | `MAIL_HOST`, `MAIL_PORT`, `MAIL_USERNAME`, `MAIL_PASSWORD` | SMTP for forgot-password (optional) |
| Backend | `AI_ENABLED`, `AI_BASE_URL`, `AI_READ_TIMEOUT_MS` | AI service (`true`, `http://localhost:8000`, 20000) |
| Backend | `JUDGE0_ENABLED`, `JUDGE0_BASE_URL`, `JUDGE0_AUTH_TOKEN` | Judge0 (`true`, `http://localhost:2358`); the token must equal `JUDGE0_AUTHN_TOKEN` below |
| AI service | `GROQ_API_KEY` | LLM access; without it LLM routes answer 503 and the backend serves template fallbacks |
| AI service | `GROQ_MODEL`, `GROQ_TIMEOUT_SECONDS`, `GROQ_MAX_RETRIES` | `openai/gpt-oss-120b`, 4, 1 |
| AI service | `BYTE_DNA_WEIGHT_PREVIOUS` | weight of history in Byte DNA updates (0.7) |
| Judge0 | `JUDGE0_DB_PASSWORD`, `JUDGE0_REDIS_PASSWORD`, `JUDGE0_AUTHN_TOKEN`, `JUDGE0_SECRET_KEY_BASE` | required secrets (random strings) |
| Judge0 | `JUDGE0_WORKER_CPUS`, `JUDGE0_WORKER_MEMORY` | worker capacity, default `4.0` / `4g` (not more CPUs than the host has) |

---

## 3. Database Migrations (Flyway)

| Version | Change |
|---|---|
| V1-V3 | `users`, `learner_profiles`, `byte_dna` |
| V4-V6 | `curriculum_domains`, `topics`, `concepts` |
| V7 | `password_reset_tokens` |
| V8-V9 | cascade deletes for profile/DNA; Byte DNA enums |
| V10-V20 | `learning_progress`, `battles`, `battle_questions`, `battle_sessions`, `attempts`, `coding_challenges`, `coding_submissions`, `performance_records`, `recommendations`, `interview_sessions`, `interview_messages` |
| V21 | foreign keys |
| V22 | seed: Java curriculum |
| V23 | `coding_submissions.ai_feedback` |
| V24 | `coding_submission_test_results` (per-case results) |
| V25 | FK indexes, unique `(user_id, concept_id)` on learning_progress and `(battle_session_id, battle_question_id)` on attempts (after de-duplication), `ON DELETE CASCADE` for user-owned rows |
| V26 | `debug_exercises`, `debug_attempts` |
| V27 | seed: Charter domains (DSA, DBMS & SQL, OS, Networks, System Design, Interview Prep) and flagship Multithreading concepts |
| V28 | seed: Multithreading battles (+ boss battle) and Java coding challenges (incl. Arrays / Binary Search) |
| V29 | seed: debugging exercises (Race Conditions, Synchronization, Deadlocks) |
| V30 | `interview_messages.score/feedback` (AI rubric result per answer), `learner_stats` (XP, streak) |

Never edit an applied migration; add a new version. Seed data exists (V22, V27-V29).

---

## 4. API Reference

Base URL: `http://localhost:8080`

Every response follows this shape:
```json
{
  "success": true,
  "message": "string",
  "data": { },
  "timestamp": "ISO datetime"
}
```
List endpoints wrap their array inside a paginated `data` shape:
```json
{
  "content": [],
  "page": 0,
  "size": 20,
  "totalElements": 100,
  "totalPages": 5,
  "first": true,
  "last": false
}
```

### Auth (public — no token required)
| Method | Endpoint | Body |
|---|---|---|
| POST | `/api/auth/register` | `{ email, password, username }` |
| POST | `/api/auth/login` | `{ email, password }` |
| POST | `/api/auth/forgot-password` | `{ email }` — sends a reset link by email |
| POST | `/api/auth/reset-password` | `{ token, newPassword }` |

Register/Login return `{ token, userId, email, username }`. Use the token as `Authorization: Bearer <token>` on every other request below.

### User
| Method | Endpoint | Body |
|---|---|---|
| GET | `/api/users/me` | — |
| PUT | `/api/users/me` | `{ username?, email? }` |
| PUT | `/api/users/me/password` | `{ currentPassword, newPassword }` |
| GET | `/api/users/{id}` | — (lookup any user by id, for cross-module use) |

### LearnerProfile
| Method | Endpoint | Body |
|---|---|---|
| GET | `/api/learner-profile` | — |
| POST | `/api/learner-profile` | `{ experienceLevel, preferredLanguage, dailyGoalMinutes }` |
| PUT | `/api/learner-profile` | any subset of the above fields |

### Byte DNA
| Method | Endpoint | Body |
|---|---|---|
| GET | `/api/byte-dna` | — |
| POST | `/api/byte-dna` | `{ technicalExperience, careerGoal, interests[], preferredLanguage, confidenceAreas[], difficultyAreas[], repeatedMistakes[], learningPreferences, explanationPreferences, topicAccuracy, difficultyProgression }` |
| PUT | `/api/byte-dna` | any subset of the above fields |

### Curriculum (public data, paginated)
| Method | Endpoint | Query params |
|---|---|---|
| GET | `/api/curriculum/domains` | `page`, `size` |
| GET | `/api/curriculum/domains/{domainId}/topics` | `page`, `size` |
| GET | `/api/curriculum/topics/{topicId}/concepts` | `page`, `size` |
| GET | `/api/concepts/{conceptId}` | — |

**Note:** `Concept.id` is the stable reference other systems (LearningProgress, Battle, CodingChallenge, PerformanceRecord, Recommendation) should use to point to a concept. This field is not expected to change.

---

### Battles, coding, debugging (authenticated; writes on battles/challenges are ADMIN only)
| Method | Endpoint | Notes |
|---|---|---|
| GET | `/api/battles`, `/api/battles/{id}`, `/api/battles/{id}/questions` | |
| POST | `/api/battles/{id}/start` | learners allowed |
| POST | `/api/battle-sessions/{id}/attempts`, `/complete` | |
| GET | `/api/coding/challenges`, `/challenges/{id}`, `/concepts/{id}/challenges` | visible sample cases only, never solution/hidden cases |
| POST | `/api/coding/challenges/{id}/submissions` | `{sourceCode, language}`; 503 when execution is unavailable |
| GET | `/api/coding/submissions/{id}` | persisted per-case results (hidden cases redacted) |
| GET | `/api/debugging/exercises?conceptId=`, `/exercises/{id}` | buggy code + visible tests |
| POST | `/api/debugging/exercises/{id}/attempts` | `{code, timeSpentSeconds?}` -> status, `nextAction` (CONTINUE/RETRY/DIAGNOSE), `persistentWeakness` |
| GET | `/api/debugging/exercises/{id}/hint?level=n` | progressive hint ladder |
| POST | `/api/debugging/analyze` | `{submissionId}` diagnosis of an own coding submission |
| CRUD | `/api/admin/debugging/exercises` | ADMIN only |

### First run: register, onboard (authenticated)
Register/login return `onboardingCompleted`. While it is `false`, the learning endpoints (`/api/learning/**`, battle start and sessions, code submissions, `/api/debugging/**`, `/api/interviews/**`, `/api/visualize/**`, `/api/ai/**`) answer **403** with a message starting `ONBOARDING_REQUIRED`. Browsing the curriculum, the account, Byte DNA and the onboarding endpoints stay open; admins are exempt.

| Method | Endpoint | Notes |
|---|---|---|
| GET | `/api/onboarding/questions` | the questions to render: `id` (= field name in the answer body), `prompt`, `type`, `required`, `maxSelections`, `allowCustom`, `options[{value,label}]`; the two self-assessment questions list the active topics |
| POST | `/api/onboarding` | `{technicalExperience, preferredLanguage, careerGoal, learningStyle, explanationStyle, interests[], dailyGoalMinutes, confidenceAreas[], difficultyAreas[]}`: saves the learner profile **and** the baseline Byte DNA in one transaction. Idempotent (retaking overwrites). If the AI service is down the baseline is built locally, so onboarding never fails because of AI |
| GET | `/api/onboarding/status` | `{completed, hasLearnerProfile, hasByteDna}` |

`technicalExperience`: BEGINNER / INTERMEDIATE / ADVANCED. `learningStyle`: INTERVIEW_PREP / EXAM_READY / CONCEPTUAL_DEPTH / AUDITORY. `explanationStyle`: STORY / FUN / CINEMATIC / DIRECT. `confidenceAreas` / `difficultyAreas` are topic slugs from the questions (a topic cannot be in both).

### Visualization (authenticated, onboarding required)
The AI service parses the Java code, simulates the thread interleavings deterministically and renders SVG (no LLM on the normal path). The backend validates, caches and proxies it.

| Method | Endpoint | Notes |
|---|---|---|
| POST | `/api/visualize` | `{code (<=20000 chars), mode?: AUTO\|RACE\|SAFE\|DEADLOCK, concept?, allowAiFallback?}`; `allowAiFallback` (default false) lets the LLM extract the thread model when the parser finds none |
| POST | `/api/visualize/flow` | `{code, method?}`: control-flow graph |
| GET | `/api/visualize/concepts/{conceptId}` | ready-made visualization (the buggy code of a seeded debugging exercise); 404 if the concept has none |

Response (for the Flutter client to animate; `svg` is the server-rendered fallback): `schedules[]` with `kind` (SAFE / RACE / DEADLOCK), `threads`, `steps[]` (`index, thread, opIndex, kind READ|WRITE|LOCK|..., target, line, text, hazard, value, local|wrote`), `expected`, `actual`/`finalValues`; `hazards[]` (`type, variables, threads, schedule, steps[] (indexes into that schedule), expected, actual, explanation, fixSuggestion`); `svg{safe,race,...}`; `notes`; `confidence`; `fixSuggestion`. Suggested split: Flutter plays `steps` with a scrubber and highlights `hazards[].steps`; the LLM is only for short captions/analogies (`/api/ai/analogy`), which can be cached per concept.

### Learning loop, interview, gamification (authenticated)
| Method | Endpoint | Notes |
|---|---|---|
| POST | `/api/learning/start` | `{conceptId}`: begins at UNDERSTAND |
| GET | `/api/learning`, `/api/learning/{id}` | the caller's progress |
| POST | `/api/learning/complete-stage` | `{progressId}`: content stages only (Understand, Visualize, Relate, Remember, Improve). BATTLE / CODE / DEBUG / INTERVIEW return 409: they advance only from a passing verified result |
| POST | `/api/interviews` | `{conceptId, difficulty}`: the first question is generated by the AI service |
| POST | `/api/interviews/{id}/messages` | `{content}`: the answer is graded against the AI rubric; the reply carries `score`, `feedback` and the next question (max 5 answers) |
| POST | `/api/interviews/{id}/complete` | score = mean of the rubric scores; idempotent |
| GET | `/api/gamification/me` | `{xp, level, streakDays}`; XP is awarded by the backend only |

### Also available
`/api/performance/**`, `/api/recommendations/**`, `/api/ai/**` (Python AI bridge: explanation, analogy, mnemonic, hints, boss battle, interview, diagnosis, Byte DNA evolution).

---

## 5. Key Design Notes

- **Auth:** stateless JWT. `JwtAuthFilter` validates the token on every request; `SecurityConfig` marks `/api/auth/**` as public and everything else as requiring a valid token.
- **"Me" endpoints:** LearnerProfile, ByteDNA, and User `/me` endpoints all resolve the current user from the JWT via `SecurityContextHolder`, not from a URL parameter.
- **Evidence loop:** every graded activity (battle, coding, debugging, interview) writes a performance record, awards XP/streak (`ProgressionService`), advances the learning stage on a pass, and asynchronously runs diagnose -> Byte DNA evolution -> recommendation (`PersonalizationAiService`). Correctness is always decided by the backend or Judge0, never by the LLM.
- **AI requests are grounded:** `AiPromptBuilder` sends the real concept/topic and the learner's stored Byte DNA; the AI service grounds the answer in its curated content index.
- **Errors:** all exceptions are caught centrally in `GlobalExceptionHandler` (package `exception`) and converted into the standard response shape with an appropriate HTTP status:
  - `ResourceNotFoundException` → 404
  - `BadRequestException` → 400
  - `UnauthorizedException` → 401
  - `ForbiddenException` → 403
  - `ConflictException` → 409
  - Validation errors (`@Valid` failures) → 400, with field-level messages in `data`
- **User table fields:** `name` (not `username`), `passwordHash` (not `password`), `active` (Boolean, for enabling/disabling accounts). The public API still uses `username` as the JSON key for compatibility — only the internal Java/DB field is `name`.

---

## 6. Tests

Unit and WebMvc tests (Mockito, MockRestServiceServer; H2 profile, no external services) live in `src/test/java`. Run `./mvnw -o -q clean test`.

Other suites: `cd ai-service && .venv/bin/python -m pytest -q` (AI service and simulator) and `cd frontend && flutter test` (client, including the visualization engine, narration and speech-reliability tests with fake engines; real audio is checked by listening in a browser).

With the whole stack running (Postgres, Judge0, AI service, backend) `python3 scripts/e2e_smoke.py` exercises a real learner journey (AI, Judge0, battle, debugging, interview, XP, Byte DNA) and exits non-zero if anything is broken.

---

## 7. Known Limitations / Next Steps

- The Flutter client in `frontend/` has been run and tested on the web (`flutter run -d web-server`). It has not been tested on a physical Android or iOS device, and the Linux desktop target is not supported (the text-to-speech plugin has no Linux implementation).
- Spoken narration uses the platform's own voices. In a browser, quality and availability depend on the voices installed (Chrome's English voices are network voices and need internet). Captions work without any voice.
- The concept visualizer simulates a *teaching model* of the code, not a JVM trace. It models simple shared-variable updates, locks and a few patterns; anything it cannot evaluate accurately (for example some arithmetic on shared values) is reported as unsupported.
- The visualizer understands Java thread code (race, safe, deadlock); other languages/concepts need extractor support in the AI service. The onboarding guard remembers completed users in memory (cleared on restart, then re-checked in the DB).
- Concept/Topic/Domain have read APIs only; content is managed through Flyway seed migrations.
- Password reset emails need valid SMTP credentials configured locally.
- Judge0 compiles once per test case, so a Java submission takes roughly 5-12 s end to end.
- Battle hints (`/api/ai/battle-hint`) are not yet counted as "hints used" in the battle evidence.

---

## 8. License

Released under the [MIT License](LICENSE). Copyright (c) 2026 Ilma Masroor. Third-party components (Judge0 CE, Flutter, Spring Boot, FastAPI and others) keep their own licenses.
