from typing import Any, Dict

from pydantic import BaseModel, Field

from app.models.llm_response import LLMResponse


class DebuggingHintRequest(BaseModel):
    concept: Dict[str, Any] = {}
    diagnosis: Dict[str, Any] = {}
    hintLevel: int = 1


class DebuggingHintResponse(LLMResponse):
    hint: str = Field(min_length=1)
