from typing import Any, Dict, List
from pydantic import BaseModel


class BossBattleRequest(BaseModel):
    concept: Dict[str, Any] = {}
    canonicalKnowledge: Dict[str, Any] = {}


class BossBattleResponse(BaseModel):
    scenario: str
    suggestedOptions: List[str]
