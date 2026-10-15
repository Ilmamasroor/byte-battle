-- Per-test-case results of a coding submission. stdout_snippet is only stored for visible (sample) cases.
CREATE TABLE coding_submission_test_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    submission_id UUID NOT NULL REFERENCES coding_submissions(id) ON DELETE CASCADE,
    case_number INTEGER NOT NULL,
    hidden BOOLEAN NOT NULL DEFAULT false,
    passed BOOLEAN NOT NULL,
    status VARCHAR(50) NOT NULL,
    time_ms INTEGER,
    memory_kb INTEGER,
    stdout_snippet TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_cstr_submission_id ON coding_submission_test_results(submission_id);
