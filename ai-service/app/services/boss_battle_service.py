from app.models.boss_battle_models import BossBattleRequest, BossBattleResponse
from app.core.prompt_safety import SAFETY_SYSTEM, wrap_learner_data, wrap_reference
from app.services import grounding
from app.services.ai_service import generate_json


def generate_boss_battle_content(data: BossBattleRequest) -> dict:
    reference = grounding.reference_for_request(data.concept, data.canonicalKnowledge)
    knowledge = (
        wrap_learner_data("canonical_knowledge", data.canonicalKnowledge, 3000)
        if data.canonicalKnowledge
        else (wrap_reference("curated_content", reference) if reference else "(none available)")
    )
    prompt = f"""
You are Byte Battle's Boss Battle Content Generator.

Generate a technical boss battle scenario based on the given concept.

CONCEPT:
{wrap_learner_data("concept", data.concept, 500)}

CANONICAL TECHNICAL KNOWLEDGE:
{knowledge}

RULES:

1. Create one realistic technical scenario.
2. Make it challenging but understandable.
3. Use canonical knowledge as the technical source.
4. Do not invent technical facts.
5. Generate exactly 4 answer options.
6. Do NOT decide or provide the correct answer.
7. The correct answer will be verified and locked manually by the backend team.
8. Keep the scenario relevant to the given difficulty.
9. Return only valid JSON.

RETURN EXACTLY:

{{
    "scenario": "...",
    "suggestedOptions": [
        "...",
        "...",
        "...",
        "..."
    ]
}}
"""

    return generate_json(prompt, BossBattleResponse, system=SAFETY_SYSTEM)
