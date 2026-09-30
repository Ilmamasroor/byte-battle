CREATE TABLE learner_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id),
    experience_level VARCHAR(30) NOT NULL,
    preferred_language VARCHAR(50) NOT NULL,
    daily_goal_minutes INTEGER NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_learner_profiles_user_id ON learner_profiles(user_id);