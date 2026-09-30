CREATE TABLE coding_submissions (
    id UUID PRIMARY KEY,
    coding_challenge_id UUID NOT NULL,
    user_id UUID NOT NULL,
    source_code TEXT,
    language VARCHAR(255),
    status VARCHAR(255),
    execution_time_ms INTEGER,
    memory_used_bytes BIGINT,
    test_cases_passed INTEGER,
    test_cases_total INTEGER,
    error_message TEXT,
    submitted_at TIMESTAMPTZ
);