from app.models.boss_battle_models import BossBattleRequest
from app.services.ai_service import generate_json


def generate_boss_battle_content(data: BossBattleRequest) -> dict:
    prompt = f"""
You are Byte Battle's Boss Battle Content Generator.

Generate a technical boss battle scenario based on the given concept.

CONCEPT:
{data.concept}

CANONICAL TECHNICAL KNOWLEDGE:
{data.canonicalKnowledge}

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

    return generate_json(prompt)
