from fastapi import APIRouter

from app.models.boss_battle_models import BossBattleRequest
from app.services.boss_battle_service import generate_boss_battle_content

router = APIRouter()


@router.post("/boss-battle/generate-content")
def boss_battle_content(data: BossBattleRequest):
    try:
        return generate_boss_battle_content(data)

    except Exception as e:
        print("BOSS BATTLE ERROR:", repr(e))
        return {
            "error": "AI service temporarily unavailable",
            "details": str(e)
        }
