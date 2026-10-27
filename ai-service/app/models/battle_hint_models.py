from typing import Any, Dict, Optional

from pydantic import BaseModel, Field

from app.models.llm_response import LLMResponse


class BattleHintRequest(BaseModel):
    concept: Dict[str, Any] = {}
    question: str = ""
    canonicalKnowledge: Dict[str, Any] = {}
    hintLevel: int = 1


class BattleHintResponse(LLMResponse):
    hintLevel: Optional[int] = None
    hint: str = Field(min_length=1)
    nextStep: str = Field(min_length=1)
