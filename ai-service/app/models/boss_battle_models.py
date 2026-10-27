from typing import Any, Dict, List

from pydantic import BaseModel, Field, field_validator

from app.models.llm_response import LLMResponse


class BossBattleRequest(BaseModel):
    concept: Dict[str, Any] = {}
    canonicalKnowledge: Dict[str, Any] = {}


class BossBattleResponse(LLMResponse):
    scenario: str = Field(min_length=1)
    suggestedOptions: List[str] = Field(min_length=4, max_length=4)

    @field_validator("suggestedOptions")
    @classmethod
    def options_not_empty(cls, options: List[str]) -> List[str]:
        cleaned = [option.strip() for option in options]

        if any(not option for option in cleaned):
            raise ValueError("options must not be empty")

        return cleaned
