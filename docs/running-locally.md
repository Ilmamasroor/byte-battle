# Running Byte Battle locally

## Prerequisites
Java 17+ (JDK 21 works), Docker (Postgres and Judge0), the Python AI service in `ai-service/` (needs Python 3.11+).

## 1. PostgreSQL
If port 5432 is already taken (for example by an old Judge0 database container), publish the app database on another port and set `DB_URL=jdbc:postgresql://localhost:5433/bytebattle_db`.
```bash
docker run -d --name bytebattle-pg -e POSTGRES_PASSWORD=<choose> -e POSTGRES_DB=bytebattle_db -p 5432:5432 postgres:16.2
```
Flyway creates and seeds the schema on first start (migrations V1-V29, `src/main/resources/db/migration`). Hibernate only validates (`ddl-auto=validate`).

## 2. Environment variables
Copy `.env.example` to `.env` (git-ignored) and export it, or set the variables in your shell.

| Variable | Purpose |
|---|---|
| `SPRING_PROFILES_ACTIVE` | `dev` supplies a throwaway JWT secret and SQL logging. Local use only. |
| `DB_URL`, `DB_USERNAME`, `DB_PASSWORD` | Postgres connection (default URL `jdbc:postgresql://localhost:5432/bytebattle_db`). |
| `JWT_SECRET` | Required outside the `dev` profile (at least 32 random characters). |
| `ADMIN_BOOTSTRAP_EMAIL` | See "Admin bootstrap". |
| `CORS_ALLOWED_ORIGINS`, `FRONTEND_URL` | Frontend origin(s) and link base for reset emails. |
| `MAIL_HOST`, `MAIL_PORT`, `MAIL_USERNAME`, `MAIL_PASSWORD` | SMTP for forgot-password. |
| `AI_ENABLED`, `AI_BASE_URL`, `AI_READ_TIMEOUT_MS`, `AI_PERSONALIZATION_URL` | Python AI service (default `http://localhost:8000`). |
| `JUDGE0_ENABLED`, `JUDGE0_BASE_URL`, `JUDGE0_AUTH_TOKEN` | Code execution. The token must equal `JUDGE0_AUTHN_TOKEN` of the Judge0 stack. |
| `JUDGE0_DEFAULT_TIME_LIMIT_MS` (5000), `JUDGE0_DEFAULT_MEMORY_LIMIT_MB` (256), `JUDGE0_MAX_TIME_LIMIT_MS` (15000), `JUDGE0_MAX_MEMORY_LIMIT_MB` (512), `JUDGE0_MAX_PROCESSES_AND_OR_THREADS` (60), `JUDGE0_POLL_INTERVAL_MS`, `JUDGE0_MAX_POLL_ATTEMPTS`, `JUDGE0_OVERALL_DEADLINE_MS`, `JUDGE0_BATCH_SIZE` | Optional tuning; per-challenge limits are honoured but clamped to the maxima. |
| `CODING_AI_FEEDBACK_TIMEOUT_MS` | Cap for the asynchronous AI feedback call (default 8000). |

With `JUDGE0_ENABLED=false` or Judge0 unreachable, code submissions return HTTP 503 and nothing is persisted as learner evidence.

## 3. Judge0
See `judge0/README.md`: `cp .env.example .env`, fill in the four secrets, `docker compose up -d` (or `docker-compose up -d`). It listens on `127.0.0.1:2358` only.

Judge0 compiles every test case separately, in parallel, so the workers need real CPU: the compose file defaults to 4 CPUs / 4 GB (`JUDGE0_WORKER_CPUS`, `JUDGE0_WORKER_MEMORY`; never more CPUs than the host has). With too little CPU Java submissions fail with "Compilation time limit exceeded"; the backend reports that as 503 (not judged) instead of blaming the learner. The backend also passes cheap JVM flags to `javac` for Java (`bytebattle.judge0.java-compiler-options`).

## 4. AI service
Start `ai-service/` as described in its own README (default port 8000; needs `GROQ_API_KEY` in its `.env` for LLM features; `curl localhost:8000/health` should show `llmConfigured: true`). With `AI_ENABLED=false` or the service down, AI endpoints answer 503 and coding feedback/personalization are skipped without affecting submissions.

## 5. Backend
```bash
export SPRING_PROFILES_ACTIVE=dev DB_PASSWORD=<same as above>
./mvnw spring-boot:run          # http://localhost:8080
```

## Admin bootstrap
Register a user via `POST /api/auth/register`, set `ADMIN_BOOTSTRAP_EMAIL` to that email and restart: the user is promoted to ADMIN at startup. ADMIN is required to create/update/delete battles, coding challenges and `/api/admin/**` (debugging exercises). Learners can still start battles and submit code.

## Verify the whole stack
```bash
python3 scripts/e2e_smoke.py     # registers a throwaway user and walks the full learner loop
```

## Troubleshooting
- **Java code never judged / 503**: check `curl -H "X-Auth-Token: $JUDGE0_AUTHN_TOKEN" http://127.0.0.1:2358/system_info` and that `JUDGE0_AUTH_TOKEN` equals `JUDGE0_AUTHN_TOKEN`.
- **`docker-compose` (v1) crashes with `KeyError: 'ContainerConfig'`** when recreating a container: `docker-compose rm -sf <service>` then `docker-compose up -d <service>`.
- **Backend dies with `ClassFormatError` or a class says "Unresolved compilation problem"**: the VS Code Java extension and Maven both write `target/classes`. Stop the IDE build (or reload the window) and run `./mvnw clean test`.
- **AI venv scripts `bad interpreter`**: the venv was created in another folder. Run `.venv/bin/python -m uvicorn app.main:app --port 8000` or recreate the venv.

## Tests
```bash
./mvnw -o -q clean test        # unit and WebMvc tests; H2 test profile, Flyway disabled, no external services
```
