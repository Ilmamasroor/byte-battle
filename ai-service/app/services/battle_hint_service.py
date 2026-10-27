from app.models.battle_hint_models import BattleHintRequest, BattleHintResponse
from app.core.prompt_safety import SAFETY_SYSTEM, wrap_learner_data, wrap_reference
from app.services import grounding
from app.services.ai_service import generate_json


def generate_battle_hint(data: BattleHintRequest) -> dict:
    reference = grounding.reference_for_request(data.concept, data.canonicalKnowledge)
    knowledge = (
        wrap_learner_data("canonical_knowledge", data.canonicalKnowledge, 3000)
        if data.canonicalKnowledge
        else (wrap_reference("curated_content", reference) if reference else "(none available)")
    )
    hint_level = max(1, min(int(data.hintLevel or 1), 3))
    prompt = f"""
You are Byte Battle's Progressive Battle Hint Generator.

Help the learner solve the Battle question without directly
revealing the answer.

CONCEPT:
{wrap_learner_data("concept", data.concept, 500)}

QUESTION:
{wrap_learner_data("question", data.question, 3000)}

CANONICAL TECHNICAL KNOWLEDGE:
{knowledge}

CURRENT HINT LEVEL:
{hint_level}

HINT LEVEL RULES:

Level 1:
Give a gentle direction toward the relevant idea.

Level 2:
Point toward the relevant technical concept,
but do not reveal the answer.

Level 3:
Give a reasoning or tracing direction that helps
the learner work toward the answer.

RULES:

1. Use canonical technical knowledge as the source of truth.
2. Keep the hint technically correct.
3. Never directly reveal the answer.
4. Never provide complete code as the answer.
5. Do not solve the question for the learner.
6. Match the hint to the current hint level.
7. Keep the hint short and beginner-friendly.
8. Return only valid JSON.

RETURN EXACTLY:

{{
    "hintLevel": {hint_level},
    "hint": "...",
    "nextStep": "..."
}}
"""

    return generate_json(prompt, BattleHintResponse, system=SAFETY_SYSTEM)
