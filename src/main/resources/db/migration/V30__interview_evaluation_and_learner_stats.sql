-- Interview answers carry the AI rubric evaluation (score 0-100 + feedback); the session score is the mean.
ALTER TABLE interview_messages ADD COLUMN score INTEGER;
ALTER TABLE interview_messages ADD COLUMN feedback TEXT;

-- XP and streak are awarded by the backend only, from verified achievements (see ProgressionService).
CREATE TABLE learner_stats (
    user_id            UUID PRIMARY KEY,
    xp                 INTEGER     NOT NULL DEFAULT 0,
    streak_days        INTEGER     NOT NULL DEFAULT 0,
    last_activity_date DATE,
    created_at         TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at         TIMESTAMP WITH TIME ZONE NOT NULL,
    CONSTRAINT fk_learner_stats_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
    CONSTRAINT chk_learner_stats_nonneg CHECK (xp >= 0 AND streak_days >= 0)
);
