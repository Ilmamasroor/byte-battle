ALTER TABLE learner_profiles DROP CONSTRAINT learner_profiles_user_id_fkey;
ALTER TABLE learner_profiles ADD CONSTRAINT learner_profiles_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE byte_dna DROP CONSTRAINT byte_dna_user_id_fkey;
ALTER TABLE byte_dna ADD CONSTRAINT byte_dna_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;