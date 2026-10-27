CREATE TABLE topics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    domain_id UUID NOT NULL REFERENCES curriculum_domains(id),
    name VARCHAR(150) NOT NULL,
    description VARCHAR(1000),
    slug VARCHAR(150) NOT NULL UNIQUE,
    display_order INTEGER NOT NULL DEFAULT 0,
    active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_topics_domain_id ON topics(domain_id);