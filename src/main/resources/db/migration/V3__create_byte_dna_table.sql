CREATE TABLE byte_dna (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id),
    technical_experience VARCHAR(30) NOT NULL,
    career_goal VARCHAR(500),
    interests JSONB,
    preferred_language VARCHAR(50) NOT NULL,
    learning_preferences JSONB,
    confidence_areas JSONB,
    difficulty_areas JSONB,
    explanation_preferences JSONB,
    repeated_mistakes JSONB,
    topic_accuracy JSONB,
    difficulty_progression JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_byte_dna_user_id ON byte_dna(user_id);