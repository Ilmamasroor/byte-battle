CREATE TABLE battle_questions (
    id UUID PRIMARY KEY,
    battle_id UUID NOT NULL,
    question_text TEXT NOT NULL,
    question_type VARCHAR(255) NOT NULL,
    options TEXT,
    correct_answer VARCHAR(255) NOT NULL,
    explanation TEXT,
    points INTEGER NOT NULL,
    display_order INTEGER NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL
);