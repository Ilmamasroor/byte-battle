CREATE TABLE performance_records (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL,
    concept_id UUID NOT NULL,
    activity_type VARCHAR(255) NOT NULL,
    score INTEGER NOT NULL,
    accuracy DOUBLE PRECISION NOT NULL,
    time_spent_seconds INTEGER NOT NULL,
    attempt_count INTEGER NOT NULL,
    success BOOLEAN NOT NULL,
    created_at TIMESTAMPTZ NOT NULL
);