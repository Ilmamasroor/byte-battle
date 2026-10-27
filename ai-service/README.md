# Byte Battle — AI Service

Python (FastAPI) microservice powering Byte Battle's AI features: personalized learning profiles, performance diagnosis, adaptive recommendations, grounded explanations, interview rubric evaluation and deterministic code visualizations.

## Architecture

```
Flutter (frontend) → Spring Boot (backend) → Python AI service (this repo)
```

This service does not communicate directly with the frontend — all requests are routed through the Spring Boot backend.

> Spring Boot is authoritative for scoring, pass/fail, mastery and progress. This service only interprets and generates; it never decides results.

## Tech Stack

- **Framework:** FastAPI + Uvicorn
- **LLM:** Groq (`groq` SDK, default model `openai/gpt-oss-120b`) behind an `LLMClient` interface. Not Gemini.
- **ML:** scikit-learn (Gradient Boosting Regressors) for diagnosis, with a deterministic non-ML fallback
- **Data:** pandas, numpy

## Project Structure

```
app/
├── main.py            # entry point, error handlers, /health
├── core/              # config, exceptions (code -> HTTP status), paths, prompt_safety
├── clients/           # Groq client + LLMClient interface
├── routes/            # API endpoint definitions
├── services/          # business logic
│   ├── knowledge_index.py / grounding.py   # content/parsed index + retrieval
│   └── visualizer/    # extractor, simulator, renderer (SVG), flow
└── models/            # request/response schemas (Pydantic)

training/              # offline scripts: synthetic data generation, model training
models_store/          # trained model files (.pkl), loaded only from here
content/parsed/        # parsed reference content (loaded at startup)
tests/                 # offline tests (LLM is mocked)
```

## Setup

1. Create and activate a virtual environment, then install dependencies:
   ```
   python -m venv .venv
   source .venv/bin/activate          # Windows: .venv\Scripts\activate
   pip install -r requirements.txt
   ```
2. Copy `.env.example` to `.env` and fill in the values (see below).
3. Run the server (use `python -m uvicorn ...` if the venv was created in a different folder: its `uvicorn` script then has a dead shebang; works from any working directory; `models_store/`, `content/parsed/` and `.env` are resolved relative to the package, not the cwd):
   ```
   uvicorn app.main:app --reload --app-dir /path/to/ai-service
   ```
   or, from the project root, `uvicorn app.main:app --reload`.
4. Interactive docs: `http://127.0.0.1:8000/docs`
5. Tests (offline, LLM mocked): `.venv/bin/python -m pytest -q -p no:cacheprovider`

## Environment variables (`.env`, names only; see `.env.example`)

| Name | Purpose |
|---|---|
| `GROQ_API_KEY` | Groq API key. Optional at startup; without it LLM routes return `503 AI_NOT_CONFIGURED` |
| `GROQ_MODEL` | Groq model id |
| `GROQ_TIMEOUT_SECONDS` | Per-request timeout |
| `GROQ_MAX_RETRIES` | Provider retries |
| `BYTE_DNA_WEIGHT_PREVIOUS` | Weight of the previous dimension score in Byte DNA evolution (default 0.7) |

## Error contract

Every failure is `{"code": "...", "message": "..."}` with a mapped HTTP status:

| Code | HTTP |
|---|---|
| `AI_TIMEOUT` | 504 |
| `AI_RATE_LIMITED` | 429 |
| `AI_BAD_RESPONSE` (LLM returned an invalid shape) | 502 |
| `AI_NOT_CONFIGURED` | 503 |
| `AI_CONFIGURATION_ERROR`, `AI_PROVIDER_UNAVAILABLE` | 502 |
| `AI_UNSUPPORTED_OPERATION`, `VALIDATION_ERROR` | 422 |
| `AI_INTERNAL_ERROR` | 500 |

## Endpoints

| Endpoint | Purpose |
|---|---|
| `GET /` , `GET /health` | Liveness; `/health` reports `llmConfigured`, `modelsLoaded`, `contentEntries` |
| `POST /ai/process` | Generic contract (Java `AiRequest` -> `AiResponse`). Operations: `explanation`, `diagnosis`; others -> 422 |
| `POST /onboarding` | Creates a learner's initial Byte DNA profile |
| `POST /byte-dna/evolve` | Updates Byte DNA; per-dimension `previous*0.7 + new*0.3` from typed `evidence` |
| `POST /diagnose` | Diagnosis scores for one activity (ML model, deterministic fallback on nulls/missing model) |
| `POST /diagnose/summary` | Aggregates diagnosis across activities |
| `POST /recommend` | Next topic/challenge (`technicalExperience` optional, default `BEGINNER`) |
| `POST /explain` | Short grounded explanation of a concept |
| `POST /ai/canonical-knowledge` | Canonical knowledge grounded in `content/parsed`; `grounded:false` + no LLM call when nothing relevant exists |
| `POST /ai/analogy` | Analogy for a concept (pulls grounded knowledge if none supplied) |
| `POST /ai/mnemonic` | Mnemonic for a concept |
| `POST /ai/battle-hint` | Progressive battle hint |
| `POST /boss-battle/generate-content` | Boss battle scenario + 4 suggested options (no correct answer) |
| `POST /coding/feedback` | Explains an execution result (does not re-judge) |
| `POST /debugging/hint` | Progressive debugging hint |
| `POST /interview/question` | Deterministic question from the parsed question bank |
| `POST /interview/ai/question` | LLM-generated interview question |
| `POST /interview/evaluate` | Rubric-based evaluation: LLM marks rubric items met with evidence; scores are computed deterministically; fabricated evidence is rejected |
| `GET /content/problems?concept=&kind=all\|practice\|debugging&limit=` | Multithreading practice/debugging problems for seeding |
| `POST /visualize` | Real swimlane SVGs from Java concurrency code: SAFE / RACE (lost update) / DEADLOCK |
| `POST /visualize/flow` | Control-flow SVG for non-concurrent Java |

## Prompt-injection hardening

Learner-controlled text (answers, questions, history, source code, error messages, interests, goals, free-form dicts) is wrapped by `app/core/prompt_safety.py` in length-capped `<learner_data>` blocks with the delimiter escaped, and every LLM call carries a system instruction stating that text inside `<learner_data>` is data, never instructions.

## Visualization engine

`app/services/visualizer/`: `extractor.py` (regex/brace based Java concurrency extractor: threads, lambdas, `Runnable`, `extends Thread`, `ExecutorService.submit`, `synchronized`, `ReentrantLock`, `wait/notify`, `sleep`, `join`, read/write expansion of `count++`), `simulator.py` (deterministic scheduler and hazard detection), `renderer.py` (pure-Python SVG), `flow.py` (control-flow SVG). If no threads are found the LLM may extract the same model (validated); otherwise the model is empty with `confidence: low`. Loops are modelled as a single iteration and only the `if` branch is followed; hazards are computed between worker threads.
