from typing import Any, Dict
from pydantic import BaseModel


class BattleHintRequest(BaseModel):
    concept: Dict[str, Any] = {}
    question: str = ""
    canonicalKnowledge: Dict[str, Any] = {}
    hintLevel: int = 1


class BattleHintResponse(BaseModel):
    hintLevel: int
    hint: str
    nextStep: str
