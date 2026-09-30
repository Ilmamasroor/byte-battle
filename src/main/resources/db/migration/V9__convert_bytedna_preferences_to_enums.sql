ALTER TABLE byte_dna DROP COLUMN learning_preferences;
ALTER TABLE byte_dna DROP COLUMN explanation_preferences;
ALTER TABLE byte_dna ADD COLUMN learning_preferences VARCHAR(50);
ALTER TABLE byte_dna ADD COLUMN explanation_preferences VARCHAR(50);