# BYTE BATTLE — SYSTEM ARCHITECTURE

**Adaptive Technical Learning & Interview Readiness Platform**

- **Project:** Byte Battle
- **Architecture Type:** AI-Integrated Layered Architecture
- **Project Stage:** MVP / Contest Prototype
- **Development Constraint:** 15 Days
- **Revision:** 7 September 2026

---

## 1. Architecture Overview

Byte Battle uses a layered architecture designed around a strict separation between deterministic system logic and AI-powered interpretation.

The architecture is built around one principle:

> AI interprets and adapts. The system verifies and decides.

The Spring Boot backend remains the authoritative application layer. It owns authentication, business rules, learner state, scoring, mastery calculations, recommendation decisions, and orchestration.

The AI service provides interpretation and personalization but does not directly control application state.

---

## 2. High-Level Architecture

```
                         BYTE BATTLE
                              │
                              ▼
                    ┌──────────────────┐
                    │  Flutter Client  │
                    │  Learner UI/UX   │
                    └────────┬─────────┘
                             │
                       HTTPS / REST
                             │
                             ▼
                  ┌──────────────────────┐
                  │   Spring Boot Core   │
                  │   Authoritative API  │
                  └──────────┬───────────┘
                             │
            ┌────────────────┼─────────────────┐
            │                │                 │
            ▼                ▼                 ▼
     ┌─────────────┐  ┌─────────────┐  ┌──────────────┐
     │ PostgreSQL  │  │ Python AI   │  │    Judge0    │
     │             │  │   Service   │  │ / Sandbox    │
     └─────────────┘  └─────────────┘  └──────────────┘
```

### Communication

```
Flutter
   │
   │ HTTPS / REST
   ▼
Spring Boot
   │
   ├── REST / HTTPS ──► Python AI Service
   │
   └── REST / HTTPS ──► Judge0 / Sandbox
   │
   └── Database Connection ──► PostgreSQL
```

The AI service and code-execution service do not directly modify PostgreSQL or authoritative learner state.

---

## 3. Technology Stack

| Layer | Technology | Responsibility |
|---|---|---|
| Client | Flutter | Learner interface and interaction |
| Core Backend | Java + Spring Boot | APIs, business logic, authentication, orchestration |
| Database | PostgreSQL | Persistent application and learner data |
| AI Service | Python + AI/LLM | Interpretation, personalization, diagnosis, explanations |
| Code Execution | Judge0 / Sandboxed Execution | Compilation and controlled test execution |
| Version Control | Git + GitHub | Source control and collaborative development |
| MVP Deployment | Docker Compose | Reproducible local/integrated service environment |

---

## 4. Core Architectural Principle

Byte Battle separates responsibilities into two categories.

### Deterministic Responsibilities

Owned by Spring Boot and supporting deterministic services:

- Code correctness
- Test-case execution
- Battle scoring
- Progress calculation
- Mastery calculation
- Learner state
- XP / streak calculation
- Application state
- Authentication
- Authorization
- Recommendation rules
- Database persistence

### AI Responsibilities

Handled by the AI service:

- Personalized explanations
- Concept simplification
- Analogies
- Memory aids
- Contextual hints
- Explanation interpretation
- Performance interpretation
- Pattern identification
- Weakness identification
- Recommendation assistance
- Technical interview interaction

AI outputs are treated as untrusted suggestions until validated and applied by Spring Boot according to application rules.

---

## 5. Core Backend Modules

The Spring Boot backend is organized into clear functional modules.

```
Spring Boot Backend
│
├── Authentication & User Management
├── Curriculum & Concept Management
├── Battle Engine
├── Code Execution Orchestration
├── Performance & Mastery
├── Byte DNA State Management
├── Recommendation Engine
├── AI Orchestration
└── Interview Management
```

### Suggested Package Structure

```
com.bytebattle
│
├── auth
├── curriculum
├── battle
├── execution
├── performance
├── bytedna
├── recommendation
├── ai
└── interview
```

The package structure mirrors the major architectural responsibilities to keep the codebase understandable and maintainable.

---

## 6. End-to-End Learning Flow

The architecture supports the complete Byte Battle learning loop:

```
                    ┌───────────────┐
                    │   ONBOARDING  │
                    └───────┬───────┘
                            │
                            ▼
                    ┌───────────────┐
                    │ INITIAL BYTE  │
                    │      DNA      │
                    └───────┬───────┘
                            │
                            ▼
                    ┌───────────────┐
                    │   UNDERSTAND  │
                    └───────┬───────┘
                            │
                            ▼
                    ┌───────────────┐
                    │   VISUALIZE   │
                    └───────┬───────┘
                            │
                            ▼
                    ┌───────────────┐
                    │     RELATE    │
                    └───────┬───────┘
                            │
                            ▼
                    ┌───────────────┐
                    │    REMEMBER   │
                    └───────┬───────┘
                            │
                            ▼
                    ┌───────────────┐
                    │     BATTLE    │
                    └───────┬───────┘
                            │
                 ┌──────────┴──────────┐
                 │                     │
              PASSED                INCORRECT
                 │                     │
                 ▼                     ▼
          ┌─────────────┐      ┌────────────────────────┐
          │ +XP / STREAK│      │ SCAFFOLDED CODE /      │
          │   UPDATE    │      │ CONCEPT REMEDIATION    │
          └──────┬──────┘      └───────────┬────────────┘
                 │                          │
                 └────────────┬─────────────┘
                              ▼
                     ┌────────────────┐
                     │      CODE      │
                     └───────┬────────┘
                             │
                             ▼
                     ┌────────────────┐
                     │ JUDGE0 /       │
                     │ SANDBOX TEST   │
                     └───────┬────────┘
                             │
                    ┌────────┴────────┐
                    │                 │
                  PASSED            FAILED
                    │                 │
                    ▼                 ▼
             ┌─────────────┐   ┌─────────────┐
             │ +XP / STREAK│   │    DEBUG    │
             │   UPDATE    │   └──────┬──────┘
             └──────┬──────┘          │
                    │                 ▼
                    │          ┌─────────────┐
                    │          │   RETEST    │
                    │          └──────┬──────┘
                    │                 │
                    │        ┌────────┴────────┐
                    │        │                 │
                    │      PASSED           FAILED
                    │        │                 │
                    │        │                 ▼
                    │        │              DIAGNOSE
                    │        │                 │
                    └────────┼─────────────────┘
                             │
                             ▼
                ┌──────────────────────────┐
                │ EXPLAIN / INTERVIEW      │
                │       (OPTIONAL)         │
                └────────────┬─────────────┘
                             │
                             ▼
                     ┌───────────────┐
                     │    DIAGNOSE   │
                     └───────┬───────┘
                             │
                             ▼
                    ┌──────────────────┐
                    │ UPDATE BYTE DNA  │
                    └────────┬─────────┘
                             │
                             ▼
                    ┌──────────────────┐
                    │ NEXT BEST ACTION │
                    └────────┬─────────┘
                             │
                    ┌────────┴─────────┐
                    │                  │
                    ▼                  ▼
              NEW CONCEPT         REMEDIATION
                    │                  │
                    └────────┬─────────┘
                             │
                             ▼
                       NEXT CYCLE
```

### Important Flow Rules

- Diagnosis does not depend on Explain or Interview.
- Battle, Code, Debug, and Interview activities can independently generate evidence.
- A failed Battle can route to either:
  - Scaffolded Code, when the learner demonstrates partial understanding, or
  - Concept Remediation, when evidence indicates a conceptual gap.
- A failed Debug Retest routes to Diagnosis rather than creating an endless debugging loop.
- Explain and Interview are optional evidence-generating activities.
- XP and streak updates occur immediately after verified successful activities.
- Byte DNA is updated from accumulated evidence.
- The Recommendation Engine determines the Next Best Action.

---

## 7. Learner State & Byte DNA

### What is Byte DNA?

Byte DNA is the learner's personal learning fingerprint—a living map of what they have mastered, where they struggle, and what they should do next.

Byte DNA is not a static score.

It evolves as new performance evidence is collected.

### Core Dimensions

```
                 BYTE DNA
                     │
        ┌────────────┼────────────┐
        │            │            │
        ▼            ▼            ▼
 Understanding  Application  Debugging
        │            │            │
        └────────────┼────────────┘
                     │
                     ▼
              Articulation
```

The four dimensions can be updated independently.

For example, a learner may have:

```
Understanding   = High
Application     = High
Debugging       = Medium
Articulation    = Low
```

This means the learner may successfully implement a concept while still struggling to explain the reasoning behind it.

Byte DNA therefore supports asynchronous evidence accumulation across different dimensions.

---

## 8. Byte DNA Data Model

A high-level representation:

```json
{
  "user_id": "uuid",
  "concept_id": "uuid",

  "indices": {
    "understanding": 0.72,
    "application": 0.45,
    "debugging": 0.61,
    "articulation": 0.38
  },

  "recurring_errors": [
    "off_by_one",
    "null_pointer"
  ],

  "attempt_count": 12,

  "last_attempt": "2026-09-07T10:30:00Z",

  "decay_factor": 0.85,

  "mastery_state": "developing"
}
```

### Mastery States

```
developing
    │
    ▼
proficient
    │
    ▼
mastered
```

Mastery should be based on accumulated evidence rather than a single successful attempt.

---

## 9. Byte DNA Update Logic

Historical performance should not permanently dominate current performance.

A lightweight weighted update can be used:

```
Updated Score
=
(Previous Score × 0.7)
+
(New Performance Score × 0.3)
```

This allows recent performance to influence the learner state while retaining historical context.

The exact weighting can be tuned during testing.

---

## 10. Cold-Start Handling

A new learner does not initially have accumulated performance data.

During onboarding:

```
New Learner
     │
     ▼
Onboarding / Baseline Assessment
     │
     ▼
Initial Byte DNA
     │
     ▼
First Battle
     │
     ▼
New Performance Evidence
     │
     ▼
Byte DNA Refinement
```

When a learner first joins, Byte DNA uses a baseline profile established during onboarding, which immediately refines as the first Battle signals are recorded.

---

## 11. Recommendation Engine

The Recommendation Engine converts learner-state evidence into a Next Best Action.

The MVP uses deterministic rules rather than allowing the LLM to directly decide learner routing.

### MVP Decision Rules

| Condition | Next Best Action |
|---|---|
| Understanding < 0.50 | Concept Remediation → Understand |
| Application < 0.40 | Remediation → Scaffolded Code |
| Debugging < 0.40 | Remediation → Debug |
| All relevant indices > 0.70 | Introduce New Concept |
| All relevant indices > 0.85 | Mastery → Celebrate |
| Recurring error detected | Targeted remediation for that error |
| Evidence insufficient | Continue recommended practice |

The thresholds are configuration values and can be adjusted after MVP validation.

### Recommendation Flow

```
Activity Evidence
       │
       ▼
Performance Signals
       │
       ▼
Byte DNA Update
       │
       ▼
Recommendation Engine
       │
       ▼
Next Best Action
```

AI may help explain or personalize the recommendation, but the authoritative routing decision remains with Spring Boot.

---

## 12. User Agency

Byte Battle provides a recommended progression, not an unnecessarily rigid sequence.

```
Byte DNA
   │
   ▼
Recommended Next Step
   │
   ├──────────────► Follow Recommendation
   │
   └──────────────► Skip to Challenge
```

The interface should explain why a recommendation was generated.

Example:

> Recommended because: Your application score is lower than your understanding score.

The learner can choose:

- Continue Recommendation

or:

- Skip to Challenge

The choice itself can become an additional behavioral signal.

---

## 13. AI Service Architecture

The AI service is isolated from the authoritative backend.

```
                    Spring Boot
                         │
                         │ REST / HTTPS
                         ▼
                 ┌─────────────────┐
                 │   Python AI      │
                 │     Service      │
                 └────────┬────────┘
                          │
                          ▼
                     AI / LLM
```

Spring Boot controls:

- What context is sent
- Which AI capability is requested
- How the response is interpreted
- Whether the result is accepted
- How the result affects application state

The AI service does not directly write learner state.

---

## 14. AI Request Flow

```
Learner Activity
       │
       ▼
Spring Boot
       │
       ├── Retrieve learner context
       ├── Retrieve activity evidence
       └── Build constrained AI request
                │
                ▼
          Python AI Service
                │
                ▼
              AI/LLM
                │
                ▼
        Structured AI Response
                │
                ▼
          Spring Boot
                │
                ├── Validate response
                │
                └── Apply according to rules
```

This prevents the AI model from becoming the source of truth.

---

## 15. AI Failure Handling

AI availability must not make the core learning system unusable.

If the AI service fails:

```
AI Request
    │
    ▼
AI Service Available?
    │
 ┌──┴───┐
YES     NO
 │       │
 ▼       ▼
AI     Fallback
Response  |
 │        ├── Deterministic feedback
 │        ├── Existing explanation
 │        └── Retry later
 │
 └───────┬───────┘
         ▼
     Continue Flow
```

Core activities such as Battle scoring, code verification, progress tracking, and learner-state persistence should continue without requiring an AI response.

---

## 16. Code Execution Architecture

Code execution is isolated from the main application.

```
Learner
   │
   ▼
Flutter Code Editor
   │
   ▼
Spring Boot
   │
   ▼
Execution Orchestrator
   │
   ▼
Judge0 / Sandbox
   │
   ├── Compile
   ├── Execute
   ├── Run Test Cases
   └── Apply Resource Limits
   │
   ▼
Execution Result
   │
   ▼
Spring Boot
   │
   ├── Update Submission
   ├── Update Performance
   ├── Update Byte DNA
   └── Generate Next Action
   │
   ▼
Flutter
```

---

## 17. Judge0 Failure Handling

A code failure and an execution-service failure are different events.

### Learner Code Failure

```
Code
 ↓
Judge0
 ↓
Tests Fail
 ↓
Debug
```

### Judge0 Unavailable

```
Code
 ↓
Judge0 Unavailable
 ↓
Submission Queued
 ↓
"Your code is being processed"
 ↓
Retry / Async Processing
 ↓
Result Available
```

Judge0 unavailability must not be interpreted as learner failure.

The system should distinguish:

- `FAILED_SUBMISSION`

from:

- `EXECUTION_UNAVAILABLE`

---

## 18. High-Level Core Entities

The architecture uses several core data concepts.

### Battle

```
Battle
├── battle_id
├── concept_id
├── user_id
├── difficulty
├── attempt
├── score
├── correct
└── timestamp
```

### Submission

```
Submission
├── submission_id
├── user_id
├── challenge_id
├── language
├── compile_status
├── tests_passed
├── tests_total
├── execution_time
└── timestamp
```

### Diagnosis

```
Diagnosis
├── diagnosis_id
├── user_id
├── dimension
├── weakness
├── evidence
├── severity
└── timestamp
```

### Recommendation

```
Recommendation
├── recommendation_id
├── user_id
├── reason
├── target_activity
├── priority
└── timestamp
```

These are architectural representations, not complete database specifications.

---

## 19. Authentication & Authorization

Authentication is handled through JWT-based authentication issued by Spring Boot.

```
User
 │
 ▼
Login / Registration
 │
 ▼
Spring Security
 │
 ▼
JWT Access Token
 │
 ▼
Protected API
```

### Authentication Strategy

- JWT-based authentication
- Short-lived access tokens
- Refresh-token rotation
- Secure client-side token storage
- Spring Security for request authentication

### Authorization

Role-based access controls differentiate users where applicable.

For the MVP:

```
Roles
│
├── LEARNER
└── ADMIN
```

Administrative functionality should remain limited to required MVP operations.

---

## 20. Security Architecture

### API Security

- Authentication on protected endpoints
- Role-based authorization
- Request validation
- Input sanitization
- Rate limiting for sensitive or expensive operations
- HTTPS in deployed environments

### Code Security

- Sandboxed execution
- Execution timeout
- Memory/resource limits
- Restricted environment
- No direct database access
- Controlled execution process

### AI Security

- Send only required learner context
- Do not expose credentials or secrets
- Constrain prompts
- Validate structured responses
- Prevent direct AI mutation of authoritative state

---

## 21. MVP Architecture Cut

Byte Battle's complete architecture is designed to support the broader product vision.

However, the project has a strict 15-day development constraint.

Therefore, the MVP deliberately prioritizes the core adaptive loop.

### Must-Have MVP

```
Flutter
   │
Spring Boot
   │
PostgreSQL
   │
├── Authentication
├── Concepts
├── Battle
├── Code
├── Judge0
├── Debug
├── Performance
├── Byte DNA
└── Recommendation Engine
```

AI is integrated selectively for:

- Explanations
- Hints
- Personalization
- Pattern interpretation
- Recommendations

### Simplified / Stretch Features

- Advanced technical communication evaluation
- Technical interview simulation
- Advanced AI diagnosis
- Advanced recommendation strategies

### Future Enhancements

- Redis
- Advanced asynchronous execution
- Distributed monitoring
- Production-grade deployment
- Advanced analytics
- Expanded interview capabilities

The MVP proves the adaptive learning loop rather than attempting to build the entire education ecosystem.

---

## 22. MVP Deployment Topology

For the contest prototype, services can be run using Docker Compose.

```
                    BYTE BATTLE MVP
                          │
                    Docker Compose
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
        ▼                 ▼                 ▼
   Spring Boot       Python AI          PostgreSQL
      :8080             :8000              :5432
        │
        ├──────────────► Judge0
        │
        ▼
     Flutter
```

The deployment setup is intentionally lightweight and reproducible for development and demonstration.

Production cloud deployment is outside the MVP scope.

---

## 23. Caching — Future Consideration

A caching layer is not required for the initial MVP.

If introduced later:

```
Spring Boot
     │
     ▼
   Redis
     │
     ├── Byte DNA reads
     ├── Recommendation results
     └── Frequently accessed learner state
```

Redis can later be introduced to cache Byte DNA reads and recommendation results, reducing database load and unnecessary AI service calls.

---

## 24. Error Handling Strategy

The system distinguishes between different failure categories.

```
                    FAILURE
                       │
       ┌───────────────┼────────────────┐
       │               │                │
       ▼               ▼                ▼
 Learner Error     Service Error     AI Error
       │               │                │
       ▼               ▼                ▼
  Diagnose        Retry / Queue      Fallback
       │               │                │
       └───────────────┼────────────────┘
                       ▼
                  Continue Flow
```

Examples:

| Failure | System Response |
|---|---|
| Incorrect Battle | Record evidence → remediation |
| Code test failure | Record failure → Debug |
| Debug Retest failure | Record evidence → Diagnose |
| Judge0 unavailable | Queue/retry → do not penalize learner |
| AI unavailable | Fallback → continue core flow |
| Database failure | Return controlled error → preserve consistency |
| Invalid request | Validation error → reject safely |

---

## 25. MVP Observability

The MVP will use basic structured application logging.

Important events include:

- Authentication events
- API failures
- AI-service failures
- Judge0 failures
- Code-execution requests
- Learner-state transitions
- Recommendation decisions
- Major application errors

Full production observability is deferred.

Future systems may include:

- Centralized logging
- Metrics
- Distributed tracing
- Alerting
- Performance monitoring

---

## 26. API Architecture

The API layer belongs to the Spring Boot backend.

Conceptually:

```
Flutter
   │
   ▼
REST API
   │
   ▼
Spring Boot Controllers
   │
   ▼
Services
   │
   ▼
Repositories
   │
   ▼
PostgreSQL
```

API endpoint specifications are maintained separately in:

`/docs/api/`

and should follow OpenAPI 3.0 conventions.

`architecture.md` defines the system structure; detailed endpoint contracts belong in the API documentation.

---

## 27. Data Flow — Complete System

```
                    LEARNER
                       │
                       ▼
                Flutter Client
                       │
                  HTTPS / REST
                       │
                       ▼
              Spring Boot Backend
                       │
        ┌──────────────┼──────────────┐
        │              │              │
        ▼              ▼              ▼
   PostgreSQL      AI Service       Judge0
        │              │              │
        │              ▼              │
        │            AI/LLM           │
        │                             │
        │              ▲              │
        └──────────────┼──────────────┘
                       │
                       ▼
              Performance Signals
                       │
                       ▼
                  Byte DNA
                       │
                       ▼
             Recommendation Engine
                       │
                       ▼
               Next Best Action
                       │
                       ▼
                  Flutter UI
```

---

## 28. Architectural Data Principle

Every meaningful learner interaction should produce usable evidence where appropriate.

```
Activity
   │
   ▼
Performance Signal
   │
   ▼
Persistent Evidence
   │
   ▼
Byte DNA
   │
   ▼
Diagnosis
   │
   ▼
Recommendation
   │
   ▼
Next Action
   │
   ▼
New Activity
```

This creates the adaptive loop:

> Every attempt becomes evidence.

---

## 29. Architectural Boundaries

The following boundaries must remain intact.

### Flutter

**Responsible for:**
- Presentation
- User interaction
- Local UI state
- API consumption

**Not responsible for:**
- Mastery calculation
- Authoritative scoring
- Recommendation decisions

### Spring Boot

**Responsible for:**
- Business logic
- Application state
- Authentication
- Authorization
- Performance
- Mastery
- Byte DNA
- Recommendations
- Orchestration

### PostgreSQL

**Responsible for:**
- Persistent storage
- Learner data
- Activity data
- Performance evidence
- Byte DNA state

### AI Service

**Responsible for:**
- Interpretation
- Personalization
- Language generation
- Pattern interpretation

**Not responsible for:**
- Authoritative state
- Code correctness
- Final scoring
- Direct database mutation

### Judge0 / Sandbox

**Responsible for:**
- Compilation
- Execution
- Test-case verification

**Not responsible for:**
- Learner diagnosis
- Mastery
- Recommendations

---

## 30. Architectural Decisions

| Decision | Rationale |
|---|---|
| Spring Boot as authoritative backend | Centralizes business rules and state |
| PostgreSQL | Reliable relational persistence |
| Flutter | Cross-platform learner experience |
| Isolated Python AI service | Separates AI experimentation from core application logic |
| Judge0 / sandbox | Deterministic and controlled code verification |
| REST communication | Simple and appropriate for the MVP |
| JWT authentication | Stateless API authentication |
| Rule-based recommendation engine | Predictable and testable routing |
| Four-dimensional Byte DNA | Captures multiple aspects of technical competence |
| Docker Compose | Reproducible MVP environment |
| Redis deferred | Avoids unnecessary infrastructure complexity during the 15-day MVP |

---

## 31. Design Principles

### 1. AI Is Not the Source of Truth

AI can interpret evidence but cannot arbitrarily change authoritative application state.

### 2. Evidence Over Assumption

Learner state should be derived from observable activity signals rather than unsupported assumptions about learner psychology.

### 3. Deterministic Verification

Objective activities should be evaluated through deterministic mechanisms wherever possible.

### 4. Progressive Adaptation

Byte DNA evolves as evidence accumulates.

### 5. User Agency

Recommendations guide learners without unnecessarily restricting their choices.

### 6. Failure Is Data

A failed attempt is not simply an error; it is evidence that can improve the next action.

### 7. MVP Discipline

The architecture should support future growth without forcing unnecessary infrastructure into the 15-day prototype.

---

## 32. Final Architectural Principle

```
             LEARNER ACTIVITY
                    │
                    ▼
          DETERMINISTIC EVIDENCE
                    │
                    ▼
                BYTE DNA
                    │
          ┌─────────┴─────────┐
          │                   │
          ▼                   ▼
      RULE ENGINE          AI SERVICE
          │                   │
          │             Interpretation
          │             Personalization
          │             Pattern Analysis
          │                   │
          └─────────┬─────────┘
                    ▼
             NEXT BEST ACTION
                    │
                    ▼
              LEARNER ACTIVITY
```

> AI interprets and adapts. The system verifies and decides.
>
> Every attempt becomes evidence.

Byte Battle turns technical preparation from passive content consumption into an adaptive, measurable cycle of learning, application, failure, diagnosis, and improvement.
