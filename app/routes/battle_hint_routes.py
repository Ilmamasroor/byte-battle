from fastapi import APIRouter

from app.models.battle_hint_models import BattleHintRequest
from app.services.battle_hint_service import generate_battle_hint

router = APIRouter()


@router.post("/ai/battle-hint")
def battle_hint(data: BattleHintRequest):
    try:
        hint_data = generate_battle_hint(data)
        return {
            "concept": data.concept,
            "question": data.question,
            "hint": hint_data
        }

    except Exception as e:
        print("BATTLE HINT ERROR:", repr(e))
        return {
            "error": "AI service temporarily unavailable",
            "details": str(e)
        }
