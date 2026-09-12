from typing import Any, Dict
from pydantic import BaseModel


class AnalogyRequest(BaseModel):
    concept: Dict[str, Any] = {}
    canonicalKnowledge: Dict[str, Any] = {}
    byteDNA: Dict[str, Any] = {}


class AnalogyResponse(BaseModel):
    analogy: str
    connection: str
    memoryTip: str
