from typing import Any, Dict, Optional

from pydantic import BaseModel


class ExplainRequest(BaseModel):
    concept: str
    byteDNA: Optional[Dict[str, Any]] = None
    canonicalKnowledge: Optional[Dict[str, Any]] = None
