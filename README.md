<<<<<<< HEAD
# Byte Battle — AI Service

> AI-powered intelligence layer for the Byte Battle technical learning and interview platform.

## Overview

Byte Battle is an AI-powered technical learning and interview platform designed to help learners move from understanding a concept to applying, debugging, explaining, and improving it.

This repository contains the Python FastAPI AI microservice. It provides Gemini-powered features for explanations, learner personalization, Canonical Knowledge, analogies, mnemonics, hints, coding/debugging feedback, technical interviews, Boss Battle content, and Job-Readiness summaries.

## Core Principle

**AI interprets and adapts. The system verifies and decides.**

Spring Boot remains the authoritative application layer for business rules, learner state, persistence, progress, mastery, scores, code correctness, test results, and deterministic decisions.

## Architecture

```text
Flutter
   ↓
Spring Boot
   ↓
JSON Request
   ↓
Python FastAPI AI Service
   ↓
Gemini
   ↓
JSON Response
   ↓
Spring Boot Validation
   ↓
Database / Flutter
```

Flutter should not directly call Gemini or the Python AI service.

## Tech Stack

- Python
- FastAPI
- Google Gemini
- `google-genai`
- Pydantic
- python-dotenv
- Uvicorn
- Spring Boot
- PostgreSQL

## Project Structure

```text
Byte-Battle-AI/
├── app/
│   ├── main.py
│   ├── models/
│   │   ├── __init__.py
│   │   ├── analogy_models.py
│   │   ├── diagnosis_models.py
│   │   ├── explain_models.py
│   │   └── mnemonic_models.py
│   ├── routes/
│   │   ├── __init__.py
│   │   ├── analogy_routes.py
│   │   ├── diagnosis_routes.py
│   │   ├── explain_routes.py
│   │   └── mnemonic_routes.py
│   └── services/
│       ├── __init__.py
│       ├── ai_service.py
│       ├── analogy_service.py
│       ├── diagnosis_service.py
│       └── mnemonic_service.py
├── .env
├── .gitignore
├── README.md
└── requirements.txt
```

## Setup

### 1. Clone

```bash
git clone <YOUR_GITHUB_REPOSITORY_URL>
cd Byte-Battle-AI
```

### 2. Create virtual environment

Windows:

```bash
python -m venv .venv
.venv\Scripts\activate
```

macOS/Linux:

```bash
python3 -m venv .venv
source .venv/bin/activate
```

### 3. Install dependencies

```bash
pip install -r requirements.txt
```

Or:

```bash
pip install fastapi uvicorn python-dotenv google-genai
```

## Environment Configuration

Create `.env` in the project root:

```env
GEMINI_API_KEY=YOUR_GEMINI_API_KEY
```

Never commit the real API key.

Recommended `.gitignore`:

```gitignore
.env
.venv/
__pycache__/
*.pyc
```

## Run

```bash
python -m uvicorn app.main:app --reload --port 8000
```

Service:

```text
http://127.0.0.1:8000
```

Swagger:

```text
http://127.0.0.1:8000/docs
```

ReDoc:

```text
http://127.0.0.1:8000/redoc
```

# API Endpoints

## 1. AI Explanation

### `POST /ai/explanation`

Input:

```json
{
  "concept": "Java Multithreading"
}
```

Output:

```json
{
  "concept": "Java Multithreading",
  "explanation": "Java Multithreading allows multiple threads to execute concurrently within a program. For example, one thread can download a file while another performs a calculation."
}
```

## 2. Byte DNA

### `POST /ai/byte-dna`

Input:

```json
{
  "technicalLevel": "BEGINNER",
  "experience": "6 months",
  "goals": ["Backend Developer"],
  "subjects": ["Java", "SQL"],
  "interests": ["Programming"],
  "learningPreference": "Examples"
}
```

Output:

```json
{
  "byteDNA": {
    "technicalLevel": "BEGINNER",
    "goals": ["Backend Developer"],
    "interests": ["Programming"],
    "learningPreference": "Examples",
    "strongAreas": [],
    "weakAreas": []
  }
}
```

Rule: AI must only use learner-provided information and must not invent strengths, weaknesses, skills, or experience.

## 3. Canonical Knowledge

### `POST /ai/canonical-knowledge`

Input:

```json
{
  "concept": {
    "conceptId": "123e4567-e89b-12d3-a456-426614174000",
    "topic": "Java Multithreading",
    "conceptName": "Thread Synchronization",
    "difficulty": "MEDIUM"
  }
}
```

Output:

```json
{
  "keyPoints": [
    "Synchronization controls access to shared resources.",
    "Locks help prevent concurrent modification of shared data."
  ],
  "rules": [
    "Shared mutable resources may require synchronization.",
    "Protected shared state should be accessed safely."
  ],
  "examples": [
    "Using a synchronized method to safely update a shared counter."
  ]
}
```

Flow:

```text
Concept
  ↓
Spring Boot
  ↓
Python AI Service
  ↓
Gemini
  ↓
Canonical Knowledge
  ↓
Spring Boot validation
  ↓
PostgreSQL
```

Validated Canonical Knowledge can then be reused by Analogy, Mnemonic, Interview, Hint, and other relevant AI features.

## 4. Analogy

### `POST /ai/analogy`

Input:

```json
{
  "concept": {
    "conceptName": "Race Conditions"
  },
  "canonicalKnowledge": {
    "keyPoints": [
      "Multiple threads can access shared resources."
    ],
    "rules": [
      "Shared resources may require synchronization."
    ]
  },
  "byteDNA": {
    "interests": ["gaming"],
    "technicalExperience": "BEGINNER"
  }
}
```

Output:

```json
{
  "concept": {
    "conceptName": "Race Conditions"
  },
  "analogy": {
    "analogy": "Imagine two players trying to pick up the same power-up at the same time..."
  }
}
```

Canonical Knowledge provides technical grounding; Byte DNA provides learner context.

## 5. Mnemonic

### `POST /ai/mnemonic`

Input:

```json
{
  "concept": {
    "conceptName": "Race Conditions"
  },
  "canonicalKnowledge": {
    "keyPoints": [
      "Multiple threads accessing shared data can cause unpredictable results."
    ],
    "rules": [
      "Shared resources may require synchronization."
    ]
  }
}
```

Output:

```json
{
  "concept": {
    "conceptName": "Race Conditions"
  },
  "mnemonic": {
    "mnemonic": "Race = Same resource + competing threads + unpredictable result"
  }
}
```

The mnemonic should be short, memorable, and technically correct.

## 6. Battle Hint

### `POST /ai/battle-hint`

Current input:

```json
{
  "question": "What happens when two threads modify the same shared variable?",
  "canonicalKnowledge": {
    "keyPoints": [
      "Multiple threads can access shared resources."
    ],
    "rules": [
      "Shared resources may require synchronization."
    ]
  },
  "hintLevel": 1
}
```

Current output:

```json
{
  "hintLevel": 1,
  "hint": "Look at what happens between reading and writing the value.",
  "nextStep": "Think about whether both threads can safely access the same data."
}
```

The final backend Diagnosis contract is expected to use `diagnosis.errorMessage`; this endpoint should be aligned once that contract is finalized.

## 7. Coding Feedback

### `POST /coding/feedback`

Input:

```json
{
  "concept": {
    "conceptName": "Thread Synchronization"
  },
  "diagnosis": {
    "sourceCode": "public void increment() { count++; }",
    "executionStatus": "fail",
    "testCasesPassed": 6,
    "testCasesTotal": 10,
    "errorMessage": "AssertionError: expected 1000, got 947"
  }
}
```

Output:

```json
{
  "feedback": "Your counter isn't thread-safe. The increment operation can be affected when multiple threads access the shared value concurrently."
}
```

AI does not decide code correctness, test results, pass/fail, or authoritative scores.

## 8. Debugging Hint

### `POST /debugging/hint`

Input:

```json
{
  "concept": {
    "conceptName": "Thread Synchronization"
  },
  "diagnosis": {
    "sourceCode": "public void increment() { count++; }",
    "executionStatus": "fail",
    "testCasesPassed": 6,
    "testCasesTotal": 10,
    "errorMessage": "AssertionError: expected 1000, got 947"
  },
  "hintLevel": 1
}
```

Output:

```json
{
  "hint": "Look at what happens when two threads call this method at the same time."
}
```

The AI should guide the learner instead of directly providing the complete solution.

## 9. Interview Question

### `POST /interview/question`

Input:

```json
{
  "concept": {
    "conceptName": "Race Conditions"
  },
  "canonicalKnowledge": {
    "keyPoints": [
      "A race condition can occur when multiple threads access shared data concurrently."
    ]
  },
  "conversationHistory": []
}
```

Output:

```json
{
  "question": "How would synchronization help prevent this race condition?"
}
```

The backend should maintain and send conversation history with subsequent requests. The Python service does not maintain long-term interview state itself.

## 10. Interview Evaluation

### `POST /interview/evaluate`

Input:

```json
{
  "concept": {
    "conceptName": "Race Conditions"
  },
  "canonicalKnowledge": {
    "keyPoints": [
      "A race condition can occur when multiple threads access shared data concurrently."
    ]
  },
  "question": "What is a race condition?",
  "learnerAnswer": "It's when two threads change the same variable and stuff gets messed up."
}
```

Output:

```json
{
  "conceptualCorrectness": 0.82,
  "completeness": 0.70,
  "technicalClarity": 0.78,
  "reasoning": 0.65,
  "explanation": 0.74,
  "feedback": "Good grasp of the core idea, but you should explain how timing between threads causes the problem."
}
```

Evaluation dimensions:

- `conceptualCorrectness`
- `completeness`
- `technicalClarity`
- `reasoning`
- `explanation`

Scores use `0.00–1.00`.

## 11. Boss Battle Content

### `POST /boss-battle/generate-content`

Input:

```json
{
  "concept": {
    "conceptName": "Thread Synchronization",
    "difficulty": "MEDIUM"
  },
  "canonicalKnowledge": {
    "keyPoints": [
      "Synchronization protects shared resources."
    ],
    "examples": [
      "Multiple threads updating a shared counter."
    ]
  }
}
```

Output:

```json
{
  "scenario": "Two threads are updating the same bank account balance at the same time, causing an incorrect final balance.",
  "suggestedOptions": [
    "Use synchronization around the balance update",
    "Create more threads",
    "Add a delay between operations",
    "Remove the shared variable"
  ]
}
```

AI generates the scenario and options. Backend controls the correct answer, game rules, scoring, and final battle state.

## 12. Job-Readiness Summary

### `POST /career/readiness-summary`

Input:

```json
{
  "byteDNA": {
    "careerGoal": "backend developer",
    "technicalExperience": "INTERMEDIATE",
    "strongAreas": [
      "Java Fundamentals",
      "OOP"
    ],
    "weakAreas": [
      "Multithreading",
      "System Design"
    ]
  },
  "conceptSummaries": [
    {
      "concept": "Multithreading & Concurrency",
      "battleScore": 68,
      "codingScore": 72,
      "debuggingScore": 48,
      "interviewScore": 61
    },
    {
      "concept": "Collections",
      "battleScore": 88,
      "codingScore": 91,
      "debuggingScore": 85,
      "interviewScore": 79
    },
    {
      "concept": "SQL Joins",
      "battleScore": 74,
      "codingScore": null,
      "debuggingScore": null,
      "interviewScore": 66
    }
  ]
}
```

Output:

```json
{
  "overallSummary": "You are strongest in Java fundamentals and Collections. Multithreading debugging is currently the clearest area for improvement.",
  "strengths": [
    "Java Fundamentals",
    "Collections",
    "OOP"
  ],
  "focusAreas": [
    "Multithreading debugging",
    "System Design fundamentals"
  ],
  "readinessNote": "You have a solid foundation for junior backend roles, but should strengthen concurrency and system design before interviews."
}
```

`null` means the learner has not attempted that activity. It must not automatically be treated as `0`.

The AI should not invent a hire/no-hire decision, overall percentage, or official readiness score. If a numeric readiness score is required, Spring Boot should calculate it deterministically and provide it to AI for narrative generation.

# API Summary

| # | Method | Endpoint | Purpose |
|---|---|---|---|
| 1 | POST | `/ai/explanation` | Technical explanation |
| 2 | POST | `/ai/byte-dna` | Learner profile |
| 3 | POST | `/ai/canonical-knowledge` | Reusable technical knowledge |
| 4 | POST | `/ai/analogy` | Concept analogy |
| 5 | POST | `/ai/mnemonic` | Memory aid |
| 6 | POST | `/ai/battle-hint` | Progressive battle hints |
| 7 | POST | `/coding/feedback` | Coding feedback |
| 8 | POST | `/debugging/hint` | Debugging guidance |
| 9 | POST | `/interview/question` | Interview question generation |
| 10 | POST | `/interview/evaluate` | Interview answer evaluation |
| 11 | POST | `/boss-battle/generate-content` | Boss Battle content |
| 12 | POST | `/career/readiness-summary` | Job-readiness narrative |

# AI Safety and Authority

### AI can

- Interpret learner context
- Personalize explanations
- Generate learning content
- Generate hints
- Generate interview questions
- Evaluate interview responses
- Generate narrative feedback

### AI cannot

- Directly modify PostgreSQL
- Directly modify learner Byte DNA
- Directly change mastery
- Change authoritative scores
- Mark code as correct
- Execute learner code
- Decide test-case results
- Change authentication state
- Decide the authoritative Boss Battle answer
- Make autonomous application-state decisions

AI failure should not be interpreted as learner failure.

# Testing

Start the service:

```bash
python -m uvicorn app.main:app --reload --port 8000
```

Open Swagger:

```text
http://127.0.0.1:8000/docs
```

For each endpoint:

1. Click `Try it out`.
2. Enter the request JSON.
3. Click `Execute`.
4. Verify the response structure.
5. Verify error handling for invalid or empty AI responses.

# Spring Boot Integration

The intended integration is:

```text
Flutter
   ↓
Spring Boot Controller
   ↓
Spring Boot AI Service
   ↓
Python FastAPI
   ↓
Gemini
   ↓
Python Response
   ↓
Spring Boot Validation
   ↓
Flutter
```

Spring Boot should own the external application API and call the Python AI service internally.

# Development Principles

1. Keep AI tasks endpoint-specific.
2. Send only the context required for each task.
3. Prefer structured JSON responses for multi-field outputs.
4. Validate AI responses before using them.
5. Keep deterministic decisions in Spring Boot.
6. Keep learner state in the backend/database.
7. Reuse validated Canonical Knowledge.
8. Keep interview conversation history in the backend.
9. Never expose API keys in source control.
10. AI should enhance the learner experience without becoming the authoritative application layer.

# Environment Variables

| Variable | Description |
|---|---|
| `GEMINI_API_KEY` | Google Gemini API key |

Never commit actual credentials.

# License

Add the project's official license here when the team finalizes the licensing decision.
=======
# byte-battle
AI-integrated adaptive technical learning and interview readiness platform that helps learners turn theoretical knowledge into practical coding, debugging, and technical reasoning skills.
>>>>>>> origin/main
