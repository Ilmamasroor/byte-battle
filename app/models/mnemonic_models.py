from typing import Any, Dict
from pydantic import BaseModel


class MnemonicRequest(BaseModel):
    concept: Dict[str, Any] = {}
    canonicalKnowledge: Dict[str, Any] = {}
    byteDNA: Dict[str, Any] = {}


class MnemonicResponse(BaseModel):
    mnemonic: str
    memoryTip: str
