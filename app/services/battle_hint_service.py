from app.models.battle_hint_models import BattleHintRequest
from app.services.ai_service import generate_json


def generate_battle_hint(data: BattleHintRequest) -> dict:
    prompt = f"""
You are Byte Battle's Progressive Battle Hint Generator.

Help the learner solve the Battle question without directly
revealing the answer.

CONCEPT:
{data.concept}

QUESTION:
{data.question}

CANONICAL TECHNICAL KNOWLEDGE:
{data.canonicalKnowledge}

CURRENT HINT LEVEL:
{data.hintLevel}

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
    "hintLevel": {data.hintLevel},
    "hint": "...",
    "nextStep": "..."
}}
"""

    return generate_json(prompt)
