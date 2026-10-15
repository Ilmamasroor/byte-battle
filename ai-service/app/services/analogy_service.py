from app.models.analogy_models import AnalogyRequest, AnalogyResponse
from app.core.prompt_safety import SAFETY_SYSTEM, wrap_learner_data, wrap_reference
from app.services import grounding
from app.services.ai_service import generate_json


def generate_analogy(data: AnalogyRequest) -> dict:
    reference = grounding.reference_for_request(data.concept, data.canonicalKnowledge)
    knowledge = (
        wrap_learner_data("canonical_knowledge", data.canonicalKnowledge, 3000)
        if data.canonicalKnowledge
        else (wrap_reference("curated_content", reference) if reference else "(none available; stay generic and do not state technical facts)")
    )
    prompt = f"""
You are Byte Battle's AI Analogy Generator.

Your job is to create a simple, memorable, and technically
correct real-world analogy for the given technical concept.

CONCEPT:
{wrap_learner_data("concept", data.concept, 500)}

CANONICAL TECHNICAL KNOWLEDGE:
{knowledge}

LEARNER BYTE DNA:
{wrap_learner_data("byte_dna", data.byteDNA, 2000)}

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

    return generate_json(prompt, AnalogyResponse, system=SAFETY_SYSTEM)
