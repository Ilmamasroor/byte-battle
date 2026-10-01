from typing import Any, Dict

from pydantic import BaseModel, Field

from app.models.llm_response import LLMResponse


class CodingFeedbackRequest(BaseModel):
    concept: Dict[str, Any] = {}
    diagnosis: Dict[str, Any] = {}


class CodingFeedbackResponse(LLMResponse):
    feedback: str = Field(min_length=1)
