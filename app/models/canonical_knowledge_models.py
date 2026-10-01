from typing import Any, Dict, List

from pydantic import BaseModel, Field

from app.models.llm_response import LLMResponse


class CanonicalKnowledgeRequest(BaseModel):
    concept: Dict[str, Any] = {}


class CanonicalKnowledgeResponse(LLMResponse):
    keyPoints: List[str] = Field(min_length=1)
    rules: List[str]
    examples: List[str]
