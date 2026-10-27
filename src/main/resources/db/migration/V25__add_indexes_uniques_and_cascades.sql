-- 1. Remove duplicate rows (keep the most recent) so the unique indexes below can be created.
DELETE FROM learning_progress a
USING learning_progress b
WHERE a.user_id = b.user_id
  AND a.concept_id = b.concept_id
  AND (a.updated_at < b.updated_at OR (a.updated_at = b.updated_at AND a.id < b.id));

DELETE FROM attempts a
USING attempts b
WHERE a.battle_session_id = b.battle_session_id
  AND a.battle_question_id = b.battle_question_id
  AND (a.attempted_at < b.attempted_at OR (a.attempted_at = b.attempted_at AND a.id < b.id));

-- 2. Unique indexes (one progress row per user+concept, one answer per question per session).
CREATE UNIQUE INDEX IF NOT EXISTS uq_learning_progress_user_concept ON learning_progress(user_id, concept_id);
CREATE UNIQUE INDEX IF NOT EXISTS uq_attempts_session_question ON attempts(battle_session_id, battle_question_id);

-- 3. Indexes on foreign-key columns (V10-V20 created none).
CREATE INDEX IF NOT EXISTS idx_learning_progress_concept_id ON learning_progress(concept_id);

CREATE INDEX IF NOT EXISTS idx_battles_concept_id ON battles(concept_id);
CREATE INDEX IF NOT EXISTS idx_battle_questions_battle_id ON battle_questions(battle_id);
CREATE INDEX IF NOT EXISTS idx_battle_sessions_battle_id ON battle_sessions(battle_id);
CREATE INDEX IF NOT EXISTS idx_battle_sessions_user_id ON battle_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_attempts_battle_question_id ON attempts(battle_question_id);

CREATE INDEX IF NOT EXISTS idx_coding_challenges_concept_id ON coding_challenges(concept_id);
CREATE INDEX IF NOT EXISTS idx_coding_submissions_challenge_id ON coding_submissions(coding_challenge_id);
CREATE INDEX IF NOT EXISTS idx_coding_submissions_user_challenge ON coding_submissions(user_id, coding_challenge_id);

CREATE INDEX IF NOT EXISTS idx_performance_records_user_id ON performance_records(user_id);
CREATE INDEX IF NOT EXISTS idx_performance_records_concept_id ON performance_records(concept_id);
CREATE INDEX IF NOT EXISTS idx_performance_records_user_concept_created
    ON performance_records(user_id, concept_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_recommendations_user_id ON recommendations(user_id);
CREATE INDEX IF NOT EXISTS idx_recommendations_concept_id ON recommendations(concept_id);

CREATE INDEX IF NOT EXISTS idx_interview_sessions_user_id ON interview_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_interview_sessions_concept_id ON interview_sessions(concept_id);
CREATE INDEX IF NOT EXISTS idx_interview_messages_session_id ON interview_messages(interview_session_id);

-- 4. ON DELETE CASCADE for user-owned rows (and rows owned by those rows), recreating the V21 constraints.
ALTER TABLE learning_progress DROP CONSTRAINT IF EXISTS fk_lp_user;
ALTER TABLE learning_progress ADD CONSTRAINT fk_lp_user
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE battle_questions DROP CONSTRAINT IF EXISTS fk_bq_battle;
ALTER TABLE battle_questions ADD CONSTRAINT fk_bq_battle
    FOREIGN KEY (battle_id) REFERENCES battles(id) ON DELETE CASCADE;

ALTER TABLE battle_sessions DROP CONSTRAINT IF EXISTS fk_bs_user;
ALTER TABLE battle_sessions ADD CONSTRAINT fk_bs_user
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE attempts DROP CONSTRAINT IF EXISTS fk_attempt_session;
ALTER TABLE attempts ADD CONSTRAINT fk_attempt_session
    FOREIGN KEY (battle_session_id) REFERENCES battle_sessions(id) ON DELETE CASCADE;

ALTER TABLE coding_submissions DROP CONSTRAINT IF EXISTS fk_cs_user;
ALTER TABLE coding_submissions ADD CONSTRAINT fk_cs_user
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE coding_submissions DROP CONSTRAINT IF EXISTS fk_cs_challenge;
ALTER TABLE coding_submissions ADD CONSTRAINT fk_cs_challenge
    FOREIGN KEY (coding_challenge_id) REFERENCES coding_challenges(id) ON DELETE CASCADE;

ALTER TABLE performance_records DROP CONSTRAINT IF EXISTS fk_pr_user;
ALTER TABLE performance_records ADD CONSTRAINT fk_pr_user
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE recommendations DROP CONSTRAINT IF EXISTS fk_rec_user;
ALTER TABLE recommendations ADD CONSTRAINT fk_rec_user
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE interview_sessions DROP CONSTRAINT IF EXISTS fk_is_user;
ALTER TABLE interview_sessions ADD CONSTRAINT fk_is_user
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE interview_messages DROP CONSTRAINT IF EXISTS fk_im_session;
ALTER TABLE interview_messages ADD CONSTRAINT fk_im_session
    FOREIGN KEY (interview_session_id) REFERENCES interview_sessions(id) ON DELETE CASCADE;

ALTER TABLE password_reset_tokens DROP CONSTRAINT IF EXISTS password_reset_tokens_user_id_fkey;
ALTER TABLE password_reset_tokens ADD CONSTRAINT password_reset_tokens_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
