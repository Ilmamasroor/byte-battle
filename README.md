# Byte Battle — AI Service

Python (FastAPI) microservice powering Byte Battle's AI features: personalized learning profiles, performance diagnosis, and adaptive recommendations.

## Architecture

```
Flutter (frontend) → Spring Boot (backend) → Python AI service (this repo)
```

This service does not communicate directly with the frontend — all requests are routed through the Spring Boot backend.

## Tech Stack

- **Framework:** FastAPI + Uvicorn
- **ML:** scikit-learn (Gradient Boosting Regressors)
- **Data:** pandas, numpy

## Project Structure

```
app/
├── main.py           # entry point, registers all routes
├── routes/           # API endpoint definitions
├── services/          # business logic (ML predictions)
└── models/            # request/response schemas (Pydantic)

training/               # offline scripts: synthetic data generation, model training
models_store/           # trained model files (.pkl)
content/                # parsed reference content (interview questions, coding problems)
scripts/                # one-time content-processing scripts
```

## Setup

1. Create and activate a virtual environment:
   ```
   python -m venv venv
   venv\Scripts\activate
   ```

2. Install dependencies:
   ```
   pip install -r requirements.txt
   ```

3. Run the server:
   ```
   uvicorn app.main:app --reload
   ```

4. View interactive API docs at `http://127.0.0.1:8000/docs`

## Endpoints

| Endpoint | Purpose |
|---|---|
| `POST /onboarding` | Creates a learner's initial Byte DNA profile |
| `POST /byte-dna/evolve` | Updates Byte DNA based on new activity results |
| `POST /diagnose` | Predicts performance diagnosis scores for a single activity |
| `POST /diagnose/summary` | Aggregates diagnosis across multiple activities |
| `POST /recommend` | Recommends next topic/challenge based on Byte DNA and performance |
