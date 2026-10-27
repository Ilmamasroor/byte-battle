CREATE TABLE interview_sessions (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL,
    concept_id UUID NOT NULL,
    status VARCHAR(255) NOT NULL,
    difficulty VARCHAR(255) NOT NULL,
    started_at TIMESTAMPTZ NOT NULL,
    completed_at TIMESTAMPTZ,
    score INTEGER,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL
);