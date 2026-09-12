# Byte Battle Backend — Developer 1

Backend for **Byte Battle**, a gamified technical learning platform. This document covers everything built by **Developer 1**: Foundation, Security (Auth), User, LearnerProfile, ByteDNA, and Curriculum.

Battle logic, Attempts, Coding challenges, Performance tracking, Recommendations, Interview/AI features belong to **Developer 2** and are not covered here.

---

## 1. Tech Stack

| Layer | Technology |
|---|---|
| Language / Framework | Java 17, Spring Boot 3.5.11 |
| Build tool | Maven |
| Database | PostgreSQL |
| Migrations | Flyway |
| Auth | Spring Security + JWT (jjwt) |
| Email | Spring Mail (Gmail SMTP) — used for Forgot Password |
| Testing | JUnit 5 + Mockito |

Root package: `com.bytebattle.byte_battle_backend`

---

## 2. Local Setup

1. Install PostgreSQL, create a database (e.g. `bytebattle_db`).
2. Update `src/main/resources/application.properties` with your DB credentials:
   - `spring.datasource.url`, `spring.datasource.username`, `spring.datasource.password`
3. For the Forgot Password feature, update the mail settings in the same file:
   - `spring.mail.username` — a Gmail address
   - `spring.mail.password` — a Gmail **App Password** (not your normal Gmail password; generate one at myaccount.google.com/apppasswords, requires 2-Step Verification enabled)
4. Run the app (`ByteBattleBackendApplication.java`). Flyway will automatically create all tables on first run.
5. Default port: `8080`

---

## 3. Database Migrations (Flyway)

| Version | Table / Change |
|---|---|
| V1 | `users` |
| V2 | `learner_profiles` |
| V3 | `byte_dna` |
| V4 | `curriculum_domains` |
| V5 | `topics` |
| V6 | `concepts` |
| V7 | `password_reset_tokens` |
| V8 | Added `ON DELETE CASCADE` to `learner_profiles`/`byte_dna` foreign keys |
| V9 | Converted `byte_dna` preference fields from free-form JSON to fixed enums |

**⚠️ Coordination note for Developer 2:** Developer 1 has used migration versions V1–V9. When merging both developers' `db/migration` folders into one, make sure no version numbers collide, and confirm the next available version number before adding new migrations.

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

**Note for Developer 2:** `Concept.id` is the stable reference other systems (LearningProgress, Battle, CodingChallenge, PerformanceRecord, Recommendation) should use to point to a concept. This field is not expected to change.

---

## 5. Key Design Notes

- **Auth:** stateless JWT. `JwtAuthFilter` validates the token on every request; `SecurityConfig` marks `/api/auth/**` as public and everything else as requiring a valid token.
- **"Me" endpoints:** LearnerProfile, ByteDNA, and User `/me` endpoints all resolve the current user from the JWT via `SecurityContextHolder`, not from a URL parameter.
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

Unit tests (Mockito-based, no real DB needed) live in `src/test/java`:
- `security/AuthServiceTest.java` — register/login logic
- `user/UserServiceTest.java` — change password / profile logic

Run via right-click → Run As → JUnit Test in your IDE, or `mvn test`.

---

## 7. Known Limitations / Next Steps

- Curriculum tables have no seed data yet — list endpoints will return empty pages until content is added.
- `Concept`, `Topic`, `CurriculumDomain` currently only have read (GET) APIs; create/update APIs for content management are not built yet.
- Password reset emails require a valid Gmail App Password configured locally; this is not yet wired to a production email provider.
