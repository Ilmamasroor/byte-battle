from typing import Any, Dict
from pydantic import BaseModel


class DebuggingHintRequest(BaseModel):
    concept: Dict[str, Any] = {}
    diagnosis: Dict[str, Any] = {}
    hintLevel: int = 1


class DebuggingHintResponse(BaseModel):
    hint: str
