CREATE TABLE battles (
    id UUID PRIMARY KEY,
    concept_id UUID NOT NULL,
    title VARCHAR(255) NOT NULL,
    description VARCHAR(255),
    battle_type VARCHAR(255) NOT NULL,
    difficulty VARCHAR(255) NOT NULL,
    total_questions INTEGER NOT NULL,
    time_limit_seconds INTEGER NOT NULL,
    total_lives INTEGER NOT NULL,
    status VARCHAR(255) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL
);