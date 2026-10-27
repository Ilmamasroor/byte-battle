from typing import Any, Dict

from pydantic import BaseModel, Field

from app.models.llm_response import LLMResponse


class MnemonicRequest(BaseModel):
    concept: Dict[str, Any] = {}
    canonicalKnowledge: Dict[str, Any] = {}
    byteDNA: Dict[str, Any] = {}


class MnemonicResponse(LLMResponse):
    mnemonic: str = Field(min_length=1)
    memoryTip: str = Field(min_length=1)
