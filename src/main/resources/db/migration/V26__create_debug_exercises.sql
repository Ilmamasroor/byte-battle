CREATE TABLE debug_exercises (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    concept_id UUID NOT NULL REFERENCES concepts(id),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    buggy_code TEXT NOT NULL,
    language VARCHAR(50) NOT NULL,
    test_cases_json TEXT NOT NULL,
    hint_ladder_json TEXT,
    bug_category VARCHAR(100),
    difficulty VARCHAR(50),
    solution_code TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_debug_exercises_concept_id ON debug_exercises(concept_id);

CREATE TABLE debug_attempts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    exercise_id UUID NOT NULL REFERENCES debug_exercises(id) ON DELETE CASCADE,
    submitted_code TEXT NOT NULL,
    status VARCHAR(50) NOT NULL,
    tests_passed INTEGER NOT NULL DEFAULT 0,
    tests_total INTEGER NOT NULL DEFAULT 0,
    error_category VARCHAR(50),
    hints_used INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_debug_attempts_user_exercise_created ON debug_attempts(user_id, exercise_id, created_at DESC);
CREATE INDEX idx_debug_attempts_exercise_id ON debug_attempts(exercise_id);
