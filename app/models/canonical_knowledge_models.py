from typing import Any, Dict, List
from pydantic import BaseModel


class CanonicalKnowledgeRequest(BaseModel):
    concept: Dict[str, Any] = {}


class CanonicalKnowledgeResponse(BaseModel):
    keyPoints: List[str]
    rules: List[str]
    examples: List[str]
