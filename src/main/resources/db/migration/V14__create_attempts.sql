CREATE TABLE attempts (
    id UUID PRIMARY KEY,
    battle_session_id UUID NOT NULL,
    battle_question_id UUID NOT NULL,
    answer VARCHAR(255) NOT NULL,
    correct BOOLEAN NOT NULL,
    points_earned INTEGER NOT NULL,
    time_taken_seconds INTEGER NOT NULL,
    status VARCHAR(255) NOT NULL,
    attempted_at TIMESTAMPTZ NOT NULL
);