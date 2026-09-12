from app.models.canonical_knowledge_models import CanonicalKnowledgeRequest
from app.services.ai_service import generate_json


def generate_canonical_knowledge(data: CanonicalKnowledgeRequest) -> dict:
    prompt = f"""
You are Byte Battle's technical knowledge generator.

Generate SHORT canonical technical knowledge for:

CONCEPT:
{data.concept}

RULES:

1. Give exactly 2 key points.
2. Give exactly 2 important rules.
3. Give exactly 1 simple technical example.
4. Keep every point short and clear.
5. Focus only on the given concept.
6. Do not add unrelated information.
7. Do not provide explanations outside the JSON.
8. Return only valid JSON.

RETURN EXACTLY:

{{
    "keyPoints": [
        "...",
        "..."
    ],
    "rules": [
        "...",
        "..."
    ],
    "examples": [
        "..."
    ]
}}
"""

    return generate_json(prompt)
