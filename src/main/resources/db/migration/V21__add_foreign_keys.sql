-- Confirm exact table/column names with Developer 1 before running this.
ALTER TABLE learning_progress ADD CONSTRAINT fk_lp_user FOREIGN KEY (user_id) REFERENCES users(id);
ALTER TABLE learning_progress ADD CONSTRAINT fk_lp_concept FOREIGN KEY (concept_id) REFERENCES concepts(id);

ALTER TABLE battles ADD CONSTRAINT fk_battle_concept FOREIGN KEY (concept_id) REFERENCES concepts(id);
ALTER TABLE battle_questions ADD CONSTRAINT fk_bq_battle FOREIGN KEY (battle_id) REFERENCES battles(id);
ALTER TABLE battle_sessions ADD CONSTRAINT fk_bs_battle FOREIGN KEY (battle_id) REFERENCES battles(id);
ALTER TABLE battle_sessions ADD CONSTRAINT fk_bs_user FOREIGN KEY (user_id) REFERENCES users(id);
ALTER TABLE attempts ADD CONSTRAINT fk_attempt_session FOREIGN KEY (battle_session_id) REFERENCES battle_sessions(id);
ALTER TABLE attempts ADD CONSTRAINT fk_attempt_question FOREIGN KEY (battle_question_id) REFERENCES battle_questions(id);

ALTER TABLE coding_challenges ADD CONSTRAINT fk_cc_concept FOREIGN KEY (concept_id) REFERENCES concepts(id);
ALTER TABLE coding_submissions ADD CONSTRAINT fk_cs_challenge FOREIGN KEY (coding_challenge_id) REFERENCES coding_challenges(id);
ALTER TABLE coding_submissions ADD CONSTRAINT fk_cs_user FOREIGN KEY (user_id) REFERENCES users(id);

ALTER TABLE performance_records ADD CONSTRAINT fk_pr_user FOREIGN KEY (user_id) REFERENCES users(id);
ALTER TABLE performance_records ADD CONSTRAINT fk_pr_concept FOREIGN KEY (concept_id) REFERENCES concepts(id);

ALTER TABLE recommendations ADD CONSTRAINT fk_rec_user FOREIGN KEY (user_id) REFERENCES users(id);
ALTER TABLE recommendations ADD CONSTRAINT fk_rec_concept FOREIGN KEY (concept_id) REFERENCES concepts(id);

ALTER TABLE interview_sessions ADD CONSTRAINT fk_is_user FOREIGN KEY (user_id) REFERENCES users(id);
ALTER TABLE interview_sessions ADD CONSTRAINT fk_is_concept FOREIGN KEY (concept_id) REFERENCES concepts(id);
ALTER TABLE interview_messages ADD CONSTRAINT fk_im_session FOREIGN KEY (interview_session_id) REFERENCES interview_sessions(id);