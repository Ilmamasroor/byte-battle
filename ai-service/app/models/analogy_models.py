from typing import Any, Dict

from pydantic import BaseModel, Field

from app.models.llm_response import LLMResponse


class AnalogyRequest(BaseModel):
    concept: Dict[str, Any] = {}
    canonicalKnowledge: Dict[str, Any] = {}
    byteDNA: Dict[str, Any] = {}


class AnalogyResponse(LLMResponse):
    analogy: str = Field(min_length=1)
    connection: str = Field(min_length=1)
    memoryTip: str = Field(min_length=1)
