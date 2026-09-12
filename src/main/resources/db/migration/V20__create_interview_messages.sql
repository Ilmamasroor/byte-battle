CREATE TABLE interview_messages (
    id UUID PRIMARY KEY,
    interview_session_id UUID NOT NULL,
    role VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    sequence_number INTEGER NOT NULL,
    created_at TIMESTAMPTZ NOT NULL
);