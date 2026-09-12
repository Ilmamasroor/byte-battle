CREATE TABLE battle_sessions (
    id UUID PRIMARY KEY,
    battle_id UUID NOT NULL,
    user_id UUID NOT NULL,
    status VARCHAR(255) NOT NULL,
    current_question_number INTEGER NOT NULL,
    score INTEGER NOT NULL,
    remaining_lives INTEGER NOT NULL,
    started_at TIMESTAMPTZ NOT NULL,
    expires_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL
);
