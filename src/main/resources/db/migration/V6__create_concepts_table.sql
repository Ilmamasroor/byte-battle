CREATE TABLE concepts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    topic_id UUID NOT NULL REFERENCES topics(id),
    name VARCHAR(150) NOT NULL,
    description VARCHAR(1000),
    slug VARCHAR(150) NOT NULL UNIQUE,
    difficulty VARCHAR(20) NOT NULL,
    display_order INTEGER NOT NULL DEFAULT 0,
    active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_concepts_topic_id ON concepts(topic_id);