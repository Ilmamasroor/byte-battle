from fastapi import APIRouter

from app.models.boss_battle_models import BossBattleRequest
from app.services.boss_battle_service import generate_boss_battle_content

router = APIRouter()


@router.post("/boss-battle/generate-content")
def boss_battle_content(data: BossBattleRequest):
    return generate_boss_battle_content(data)
