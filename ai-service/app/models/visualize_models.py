from typing import Literal, Optional

from pydantic import BaseModel, Field


class VisualizeRequest(BaseModel):
    code: str = Field(min_length=1, max_length=20000)
    language: Literal["java"] = "java"
    mode: Literal["auto", "race", "safe", "deadlock"] = "auto"
    concept: Optional[str] = None
    useLlm: bool = True  # allow LLM extraction fallback when no threads are found


class FlowRequest(BaseModel):
    code: str = Field(min_length=1, max_length=20000)
    language: Literal["java"] = "java"
    method: Optional[str] = None
