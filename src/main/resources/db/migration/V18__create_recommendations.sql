CREATE TABLE recommendations (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL,
    concept_id UUID NOT NULL,
    type VARCHAR(255) NOT NULL,
    source VARCHAR(255) NOT NULL,
    priority VARCHAR(255) NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT,
    reason TEXT,
    is_completed BOOLEAN NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    expires_at TIMESTAMPTZ
);