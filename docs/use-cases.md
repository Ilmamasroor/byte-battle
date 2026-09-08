# Byte Battle — Use Cases Specification

**Project:** Byte Battle

**Tagline:** Think Deeper. Code Better.

**Type:** AI-Powered Adaptive Technical Learning & Job-Readiness Platform

**Primary Platform:** Mobile Application (Flutter)

**Flagship Domain:** Java — Multithreading & Concurrency

---

## 1. Purpose & System Overview

Byte Battle is an AI-powered adaptive technical learning and job-readiness platform designed to help learners move beyond passive theory consumption toward understanding, application, coding, debugging, technical explanation, interview readiness, and continuous improvement.

The platform follows the adaptive learning loop:

```
Understand → Visualize → Relate → Remember → Battle → Code → Debug → Explain → Diagnose → Improve
```

### Supported Domains

- Java
- Data Structures & Algorithms
- DBMS & SQL
- Operating Systems
- Computer Networks
- System Design
- Technical Interview Preparation

The Java Multithreading & Concurrency journey serves as the flagship implementation demonstrating the complete end-to-end product experience.

### Flagship Journey

```
Java → Multithreading & Concurrency → Race Conditions → Learn → Battle → Code → Debug → AI Interview → Diagnose → Next Best Action
```

### Central Architectural Principle

**AI provides intelligence. Deterministic systems provide correctness.**

- AI adapts the learning experience, interprets performance, generates explanations, and proposes recommendations.
- Deterministic application logic remains responsible for correctness, scoring, state transitions, code execution results, progress, and mastery.

---

## 2. Actors & Responsibilities

### 2.1 Technical Learner

The primary actor and end user of Byte Battle.

- Register and authenticate
- Complete onboarding
- Establish an initial Byte DNA profile
- Explore technical domains
- Learn concepts
- Interact with visual explanations
- Complete Battles
- Request progressive hints
- Write and execute Java code
- Debug broken implementations
- Participate in AI technical interviews
- Review performance
- Receive AI diagnosis
- Receive personalized recommendations
- Track progress and mastery

### 2.2 AI Service — Python / LLM

Responsible for:

- Personalized explanations
- Real-world analogies
- Mnemonics
- Progressive hints
- Content adaptation
- AI interview interaction
- Qualitative interview evaluation
- Performance interpretation
- Weakness diagnosis
- Recommendation proposals

The AI service does not own authoritative application state or deterministic technical correctness.

### 2.3 Code Execution Service — Judge0

Responsible for:

- Java compilation
- Code execution
- Test-case execution
- Raw execution result reporting
- Runtime/error metadata

Judge0 provides the isolated execution boundary for learner-submitted code. Sandbox resource and network restrictions depend on the deployed Judge0 configuration and are verified as part of deployment testing.

### 2.4 Spring Boot Backend

Responsible for:

- Authentication & JWT Session Management
- Curriculum and concept structure
- Byte DNA persistence
- Battle state
- Correctness validation
- Scoring, Timer validation, Attempts, and Lives
- Coding execution orchestration & evaluation
- Performance metrics & Mastery calculation
- AI orchestration with JSON schema validation
- Recommendation validation
- Transactional persistence & consistency enforcement

### 2.5 PostgreSQL Database

Stores:

- Users & Learner profiles (Byte DNA)
- Curriculum & Concepts
- Battles & Questions
- Attempts, Coding submissions, & Execution results
- Performance signals
- Interview sessions
- Recommendations
- Progress and mastery

---

## 3. Stakeholders

| Stakeholder | Core Interest |
|---|---|
| Technical Learner | Effective personalized learning and job readiness |
| Engineering Team | Reliable architecture, maintainable implementation, and strict data consistency |
| Evaluators / Judges | Meaningful AI integration, system resilience, and a working prototype |
| Interview Candidates | Technical reasoning, code execution, and real-time interview practice |

---

## 4. Primary Use Cases

### UC-01 — Register Account

**Priority:** P0 — Must Have
**Primary Actor:** Technical Learner
**AI Role:** None

**Goal:** Create a secure Byte Battle account.

**Main Flow:**
1. Learner enters registration details in Flutter.
2. Flutter sends registration payload to Spring Boot backend.
3. Backend validates input and password policies.
4. Backend creates the user account within an isolated transactional scope.
5. User profile and default Byte DNA record are persisted to PostgreSQL.
6. Application confirms successful registration.

**Exceptions:** Existing account → Return validation error; Invalid input → Field validation error; Backend failure → Rollback transaction and return recoverable system error.

---

### UC-02 — Login & Restore Session

**Priority:** P0 — Must Have
**Primary Actor:** Technical Learner
**AI Role:** None

**Goal:** Authenticate an existing learner and restore their session.

**Main Flow:**
1. Learner submits credentials.
2. Backend validates credentials against salted hashes.
3. Backend generates a signed JWT.
4. Flutter securely stores the token (Flutter Secure Storage).
5. Application navigates to Dashboard.

**Exceptions:** Invalid credentials → Authentication error; Expired token → Clear token & require re-auth; System offline → Show connection error.

---

### UC-03 — Complete Learner Onboarding

**Priority:** P0 — Must Have
**Primary Actor:** Technical Learner
**AI Role:** Initial Byte DNA Proposal

**Goal:** Collect learner context required to establish an initial Byte DNA profile.

**Main Flow:**
1. Learner provides background (technical level, goals, explanation style).
2. Flutter submits onboarding survey to Spring Boot.
3. AI proposes an initial Byte DNA baseline from learner-provided context.
4. Spring Boot validates the proposal against the allowed Byte DNA schema and persists the resulting profile.

**Privacy Principle:** Byte DNA relies on explicit learner input and observed performance. No hidden social-media scraping or speculative demographic assumptions.

---

### UC-04 — View Personalized Dashboard & Mission Control

**Priority:** P0 — Must Have
**Primary Actor:** Technical Learner
**AI Role:** Recommendation Proposal / Display

**Goal:** Provide the learner with a clear view of current learning state and next recommended action.

**Main Flow:**
1. Learner opens Dashboard.
2. Backend queries current progress, XP, streak, and recent diagnostic signals.
3. Backend validates/fetches current Next Best Action.
4. Flutter renders Mission Control.

---

### UC-05 — Explore Curriculum & Select Concept

**Priority:** P0 — Must Have
**Primary Actor:** Technical Learner
**AI Role:** Content Personalization

**Goal:** Allow learners to explore technical domains and select concepts.

**Flagship Hierarchy:**

```
Java
└── Multithreading & Concurrency
    ├── Threads
    ├── Shared Resources
    ├── Race Conditions
    ├── Synchronization
    ├── Locks
    └── Deadlocks
```

Deterministic curriculum structure remains authoritative. AI personalizes explanations upon selection.

---

### UC-06 — Learn a Concept Through the Concept Engine

**Priority:** P0 — Must Have
**Primary Actor:** Technical Learner
**AI Role:** Adaptive Content Delivery

**Goal:** Build conceptual understanding before practical application.

**Sequence:**

```
UNDERSTAND → VISUALIZE → RELATE → REMEMBER
```

**Responsibilities:**
- **AI:** Adapts depth, vocabulary, analogies, mnemonics, and visual captions based on Byte DNA.
- **Backend:** Enforces stage completion, tracks time spent, and manages progression state.

---

### UC-07 — Complete a Battle

**Priority:** P0 — Must Have
**Primary Actor:** Technical Learner
**AI Role:** Optional Explanations / Hints

**Goal:** Test application of conceptual knowledge under constraints (timer, lives).

**Main Flow:**
1. Backend initializes Battle session with atomic state tracking.
2. Learner submits an answer.
3. Backend validates correctness deterministically, verifies timer validity, and deducts lives/adds score inside a transactional block.
4. Performance signals (time, attempts, accuracy) are logged.

---

### UC-08 — Receive Progressive AI Hints

**Priority:** P1 — Should Have
**Primary Actor:** Technical Learner
**AI Role:** Hint Generation

**Goal:** Assist learners through structured scaffolding without spoiling solutions.

**Progression:**

```
1. Nudge → 2. Concept Hint → 3. Direction → 4. Full Explanation
```

Hint requests are logged as performance signals.

---

### UC-09 — Complete a Coding Challenge

**Priority:** P0 — Must Have
**Primary Actor:** Technical Learner
**Supporting Actor:** Judge0 Code Execution Engine

**Goal:** Convert conceptual understanding into working Java code.

**Execution Boundary:**

```
Learner → Flutter → Spring Boot → Judge0 Sandbox → Execution Results → Spring Boot Evaluation → Database/Flutter
```

**Evaluation:** Judge0 provides compilation, execution, test results, and runtime metadata. Spring Boot applies the challenge's configured evaluation criteria and determines the authoritative application outcome.

---

### UC-10 — Complete a Debugging Challenge

**Priority:** P1 — Should Have
**Primary Actor:** Technical Learner
**Supporting Actors:** Judge0 / AI Service

**Goal:** Identify and resolve synchronization bugs, race conditions, or logic errors in existing code.

**Main Flow:**
1. Learner receives broken snippet.
2. Learner modifies and submits code.
3. Judge0 compiles and executes code against test runs.
4. Spring Boot evaluates execution output; if execution fails, AI Service provides targeted error interpretation without revealing direct source fixes.

---

### UC-11 — Participate in AI Technical Interview

**Priority:** P1 — Should Have
**Primary Actor:** Technical Learner
**Supporting Actor:** AI Interviewer

**Goal:** Evaluate verbal/written technical communication and trade-off analysis.

**Dimensions:** Technical accuracy, depth, edge-case coverage, and clarity.

**Enforcement:** Spring Boot maintains turn counts, session timeouts, and conversation context.

---

### UC-12 — View Performance Analysis

**Priority:** P1 — Should Have
**Primary Actor:** Technical Learner
**AI Role:** None

**Goal:** Aggregate objective performance signals.

**Signals:** Speed, attempt frequencies, compilation errors, hint dependencies, interview rubrics, and diagnostic logs.

---

### UC-13 — Receive AI Performance Diagnosis

**Priority:** P0 — Must Have
**Primary Actor:** Technical Learner
**AI Role:** Diagnostic Pattern Analysis

**Goal:** Identify root cognitive gaps behind repeated mistakes.

**Flow:**

```
Performance Signals → Spring Boot → Strict Schema LLM Payload → AI Diagnostics → Backend JSON Schema Validation → Learner UI
```

---

### UC-14 — Update Byte DNA

**Priority:** P0 — Must Have
**Primary Actor:** Backend System
**AI Role:** Signal Interpretation

**Goal:** Dynamically evolve the learner's skill vector over time.

**Update Engine:** Combines verified performance signals with AI interpretation to adjust skill tags, topic mastery, and retention scores.

---

### UC-15 — Receive Personalized Recommendation

**Priority:** P0 — Must Have
**Primary Actor:** Technical Learner
**AI Role:** Recommendation Proposal

**Goal:** Provide an appropriate Next Best Action based on available learner evidence and system constraints (Remediation, Challenge, Review, or New Concept).

**Validation Rule:** AI proposes an action; Spring Boot validates prerequisites and user state before applying it.

---

### UC-16 — Track Progress & Mastery

**Priority:** P0 — Basic progress required for flagship loop; advanced mastery analytics P1
**Primary Actor:** Technical Learner
**AI Role:** None

**Goal:** Provide transparent progress and mastery visualization across concepts and sub-topics.

**Ownership:** All progress percentages and mastery metrics are calculated deterministically via Spring Boot business logic.

---

### UC-17 — Continue the Adaptive Learning Loop

**Priority:** P0 — Must Have
**Primary Actor:** Technical Learner
**AI Role:** Personalization Support

**Goal:** Maintain continuous feedback loop progression across the platform.

---

## 5. End-to-End Flagship System Flow

```
                     +-----------------------+
                     |    LOGIN / REGISTER   |
                     +-----------+-----------+
                                 |
                                 v
                     +-----------------------+
                     |       ONBOARDING      |
                     +-----------+-----------+
                                 |
                                 v
                     +-----------------------+
                     |        BYTE DNA       |
                     +-----------+-----------+
                                 |
                                 v
                     +-----------------------+
                     | DASHBOARD / MISSION   |
                     |        CONTROL        |
                     +-----------+-----------+
                                 |
                                 v
                     +-----------------------+
                     |    NEXT BEST ACTION   |
                     +-----------+-----------+
                                 |
                                 v
                     +-----------------------+
                     |     CONCEPT ENGINE    |
                     |  Understand ->        |
                     |  Visualize -> Relate  |
                     |  -> Remember          |
                     +-----------+-----------+
                                 |
                                 v
                     +-----------------------+
                     |         BATTLE        |
                     +-----------+-----------+
                                 |
                        +--------+--------+
                        |                 |
                        v                 v
                   [ CORRECT ]       [ INCORRECT ]
                        |                 |
                        v                 v
                   INDEPENDENT        SCAFFOLDED
                      CODE               CODE
                        |                 |
                        +--------+--------+
                                 |
                                 v
                     +-----------------------+
                     |   JUDGE0 / SANDBOX    |
                     +-----------+-----------+
                                 |
                        +--------+--------+
                        |                 |
                        v                 v
                    [ PASSED ]        [ FAILED ]
                        |                 |
                        |                 v
                        |               DEBUG
                        |                 |
                        |        +--------+--------+
                        |        |                 |
                        |        v                 v
                        |     [ PASS ]          [ FAIL ]
                        +--------+-----------------+
                                 |
                                 v
                     +-----------------------+
                     |      BOSS BATTLE      |
                     +-----------+-----------+
                                 |
                        +--------+--------+
                        |                 |
                        v                 v
                    [ PASS ]          [ FAIL ]
                        |                 |
                        v                 v
                     EXPLAIN /       REMEDIATION
                    INTERVIEW             |
                        |                 v
                        |          NEXT BEST ACTION
                        v
                     PERFORMANCE
                       SIGNALS
                                 |
                                 v
                     +-----------------------+
                     |        DIAGNOSE       |
                     +-----------+-----------+
                                 |
                                 v
                     +-----------------------+
                     |    UPDATE BYTE DNA    |
                     +-----------+-----------+
                                 |
                                 v
                     +-----------------------+
                     |    NEXT BEST ACTION   |
                     | (New Concept/Remed /  |
                     |        Mastery)       |
                     +-----------------------+
```

---

## 6. AI Fallback SLA & Resilience

To prevent AI latency or service degradation from blocking the user experience, HTTP clients interacting with AI endpoints are configured with operation-specific timeout thresholds paired with static fallbacks.

| AI Operation | Target Timeout SLA | Fallback Strategy |
|---|---|---|
| Concept Personalization | 3.0 sec | Canonical/Static explanation text |
| Progressive Hint | 3.0 sec | Static rule-based hint matching current step |
| AI Interview Response | 4.0 sec | Retried request or graceful session message |
| Performance Diagnosis | 3.5 sec | Deterministic template-driven diagnosis |
| Recommendation Proposal | 3.0 sec | Spring Boot rule engine selects Next Best Action |

### Timeout & Failure Protocol

- **Threshold Enforcement:** Spring Boot HTTP client configurations enforce maximum wait boundaries per endpoint.
- **Fallback Execution:** Pre-cached, canonical fallback payload is served immediately to Flutter upon timeout or service exception.
- **Log & Audit:** Non-blocking async event logs the AI timeout/failure for observability.
- **State Protection:** System state remains fully deterministic and uncorrupted.

---

## 7. AI Payload Validation & Schema Contracts

To ensure safety against malformed LLM responses or prompt injections, AI communications enforce input sanitization and output schema validation at the Spring Boot boundary.

```
+---------------+     Raw Response Payload  +-------------------+
|  Python LLM   | ------------------------> | Spring Boot Edge  |
|    Service    |                           |  (JSON Validator) |
+---------------+                           +---------+---------+
                                                      |
                                         +------------+------------+
                                         |                         |
                                         v                         v
                                    [ Valid Schema ]       [ Invalid Schema ]
                                         |                         |
                                         v                         v
                                   Process Payload         Reject Payload &
                                  in Business Logic          Trigger Fallback
```

### Protocol Rules

- **Input Sanitization:** User inputs, code snippets, and interview responses are stripped of control characters and validated against size constraints prior to LLM forwarding.
- **Schema Contract:** Python AI endpoints are contracted to return strict JSON structures matching predefined schemas.
- **Parse Validation:** Spring Boot parses responses with strict type checking. If parser failure or schema validation failure occurs, the payload is rejected and the SLA Fallback is invoked.

---

## 8. Transaction Isolation & State Consistency

External service calls (Judge0 execution and Python AI APIs) operate outside database transaction limits. To prevent race conditions, orphan states, or partial updates, Byte Battle designs execution around an **External Result First, Persist Atomically Second** pattern.

### State & Isolation Directives

- **Transactional Boundaries:** Database persistence operations following external service responses are executed within transactional boundaries.
- **Concurrency Control:** Critical mutable entities are designed to use optimistic locking via `@Version` fields where concurrent updates are possible (e.g., rapid submission retries or overlapping diagnostic updates).

```
                      +------------------+
                      |   User Submits   |
                      |    Java Code     |
                      +--------+---------+
                               |
                               v
                      +------------------+
                      |  Spring Boot     |
                      |  Orchestrator    |
                      +--------+---------+
                               |
                               v
                      +------------------+
                      |  Judge0 Execution|
                      |  (External API)  |
                      +--------+---------+
                               |
                               v
                      +------------------+
                      | Receive & Validate|
                      |  Execution Result|
                      +--------+---------+
                               |
                               v
            +------------------------------------------+
            |      Spring Boot Atomic Persist Scope    |
            |  BEGIN TRANSACTION                       |
            |   1. Save Code Execution Record          |
            |   2. Log Performance Signals             |
            |   3. Update Concept Mastery/Progress     |
            |   4. Mutate Byte DNA Profile             |
            |  COMMIT TRANSACTION                      |
            +------------------------------------------+
```

---

## 9. AI Decision Boundary

To ensure systemic correctness, Byte Battle strictly separates non-authoritative AI generation from authoritative backend validation and state mutation.

| System Decision / Action | AI Role | Backend (Spring Boot) Role |
|---|---|---|
| Explain Concept | Yes — Generates Explanation | Validates Structure & Pre-conditions |
| Generate Analogy | Yes — Generates Analogy | — |
| Generate Hint | Yes — Formulates Text | Controls Hint Level & Eligibility |
| Decide Answer Correctness | No | Yes — Authoritative Evaluation |
| Calculate Score & Lives | No | Yes — Authoritative Calculation |
| Validate Code Output | No | Yes — Evaluates Judge0 Test Results |
| Interpret Runtime Error | Yes — Formulates Guidance | Validates Execution Context |
| Calculate Mastery Metric | No | Yes — Authoritative Math Logic |
| Diagnose Cognitive Gap | Yes — Proposes Diagnosis | Validates Schema & Evidence Rules |
| Propose Next Action | Yes — Proposes Action | Validates Prerequisites & Applies |
| Mutate Authoritative User State | No | Yes — Authoritative Database Persistence |

**Principle:** AI may recommend, interpret, explain, and adapt. Only deterministic backend logic may authorize authoritative learner state changes.

---

## 10. Security & Responsible System Operations

- **Execution Boundary:** Code is executed via sandbox boundaries managed by Judge0. Specific resource caps (memory, CPU, network access) are governed by the underlying infrastructure configuration and verified during deployment testing.
- **Server-Authoritative Validation:** The mobile client (Flutter) is treated as untrusted. Scoring, timers, lives, correctness, and progression states are computed and verified server-side.
- **Data Privacy:** Byte DNA profiling uses explicit, in-app learning interactions. No private data or external account scraping is required.

---

## 11. Traceability Matrix

| Use Case | Core Capability | AI Role | Deterministic Role | Priority |
|---|---|---|---|---|
| UC-01/02 | Authentication & Session | None | Account creation, password hash, JWT generation | P0 |
| UC-03 | Onboarding | Initial Byte DNA proposal | Profile validation & persistence | P0 |
| UC-04 | Dashboard & Mission Control | Recommendation display | Metrics, streak, & progress calculation | P0 |
| UC-05/06 | Concept Engine | Delivery personalization | Canonical curriculum & sequence authority | P0 |
| UC-07/08 | Battle & Hints | Progressive hint generation | Correctness, timer, lives, scoring | P0 |
| UC-09/10 | Code & Debug | Error interpretation | Execution orchestration, evaluation, pass/fail | P0 |
| UC-11 | AI Interview | Dynamic question & evaluation | Turn state, timers, interview session persistence | P1 |
| UC-12/13 | Performance & Diagnosis | Pattern interpretation | Signal aggregation & diagnosis schema validation | P0 |
| UC-14/15 | Byte DNA & Recommendation | Recommendation proposal | State update & prerequisite verification | P0 |
| UC-16/17 | Mastery & Adaptive Loop | Experience adaptation | Progress & mastery algorithms, database updates | P0 |

---

## 12. End-to-End Acceptance Benchmark

The MVP specification is accepted when a learner can run through the following sequence seamlessly:

```
Register/Login → Onboarding → Java Multithreading → Race Conditions Concept → Battle
→ Write Java Code → Judge0 Execution / Pass → AI Technical Interview → AI Diagnosis
→ Byte DNA Update → Validated Next Best Action
```

Without unhandled exceptions, manual database edits, corrupted state updates, or unvalidated AI responses.

---

## 13. Definition of Done — Competition MVP

A feature or use case is classified as Done when:

- Flow completes end-to-end without unhandled application exceptions.
- Business logic, state changes, and evaluation rules are enforced server-side.
- AI inputs and output schemas are validated against expected contracts.
- AI failures/timeouts trigger standard fallbacks within designated thresholds.
- Database operations complete atomically within defined transactional scopes.
- Mobile client UI accurately reflects server-authoritative state.
- The flagship Java Concurrency path demonstrates the full learning loop.
