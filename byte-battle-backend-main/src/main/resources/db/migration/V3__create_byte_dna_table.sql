CREATE TABLE byte_dna (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id),
    learning_style VARCHAR(50) NOT NULL,
    strength_profile JSONB,
    weakness_profile JSONB,
    preferred_difficulty VARCHAR(30) NOT NULL,
    consistency_score NUMERIC(5,2) NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_byte_dna_user_id ON byte_dna(user_id);