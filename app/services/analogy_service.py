from app.models.analogy_models import AnalogyRequest
from app.services.ai_service import generate_json


def generate_analogy(data: AnalogyRequest) -> dict:
    prompt = f"""
You are Byte Battle's AI Analogy Generator.

Your job is to create a simple, memorable, and technically
correct real-world analogy for the given technical concept.

CONCEPT:
{data.concept}

CANONICAL TECHNICAL KNOWLEDGE:
{data.canonicalKnowledge}

LEARNER BYTE DNA:
{data.byteDNA}

RULES:

1. Use the canonical technical knowledge as the source of truth.
2. Do not invent or change technical facts.
3. Match the analogy to the learner's technical experience.
4. Use learner interests when available.
5. Make the analogy simple and memorable.
6. If no interest is provided, use a neutral real-world analogy.
7. Do not assume information that is not provided.
8. Clearly explain how the analogy maps to the technical concept.
9. Keep the analogy relevant to the given concept.
10. Do not use performance data for this task.
11. Return only valid JSON.

RETURN EXACTLY THIS STRUCTURE:

{{
    "analogy": "...",
    "connection": "...",
    "memoryTip": "..."
}}
"""

    return generate_json(prompt)
