from typing import Any, Dict
from pydantic import BaseModel


class CodingFeedbackRequest(BaseModel):
    concept: Dict[str, Any] = {}
    diagnosis: Dict[str, Any] = {}


class CodingFeedbackResponse(BaseModel):
    feedback: str
