from typing import Any, Dict, List, Optional

from pydantic import BaseModel, Field

from app.models.llm_response import LLMResponse


class CanonicalKnowledgeRequest(BaseModel):
    concept: Dict[str, Any] = {}


class CanonicalKnowledgeResponse(LLMResponse):
    keyPoints: List[str] = Field(min_length=1)
    rules: List[str] = []
    examples: List[str] = []
    grounded: bool = True
    sources: Optional[List[str]] = None
    requiresManualAuthoring: Optional[bool] = None
