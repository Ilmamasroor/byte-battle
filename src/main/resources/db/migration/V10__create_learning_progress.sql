CREATE TABLE learning_progress (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL,
    concept_id UUID NOT NULL,
    current_stage VARCHAR(255) NOT NULL,
    completed BOOLEAN NOT NULL,
    progress_percentage INTEGER NOT NULL,
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL
);