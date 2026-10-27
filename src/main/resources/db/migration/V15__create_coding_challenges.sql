CREATE TABLE coding_challenges (
    id UUID PRIMARY KEY,
    concept_id UUID NOT NULL,
    title VARCHAR(255),
    description TEXT,
    difficulty VARCHAR(255),
    language VARCHAR(255),
    input_description TEXT,
    output_description TEXT,
    constraints TEXT,
    starter_code TEXT,
    solution_code TEXT,
    test_cases TEXT,
    time_limit_ms INTEGER,
    memory_limit_mb INTEGER,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
);