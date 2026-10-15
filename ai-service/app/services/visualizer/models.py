from typing import Dict, List, Literal, Optional, Union

from pydantic import BaseModel, Field

OpKind = Literal["READ", "WRITE", "LOCK", "UNLOCK", "WAIT", "NOTIFY", "SLEEP", "START", "JOIN"]


class Op(BaseModel):
    kind: OpKind
    target: str = ""
    line: int = 0
    text: str = ""
    # optional semantics for WRITE ops used by the simulator
    delta: Optional[int] = None  # new = old(read) + delta
    assign: Optional[int] = None  # new = constant
    source: Optional[str] = None  # original statement text


class ThreadModel(BaseModel):
    id: str
    label: str = ""
    ops: List[Op] = []


class SharedVar(BaseModel):
    name: str
    initial: Union[int, float] = 0
    volatile: bool = False


class VisModel(BaseModel):
    threads: List[ThreadModel] = []
    shared: List[SharedVar] = []
    locks: List[str] = []
    confidence: Literal["high", "medium", "low"] = "low"
    source: Literal["deterministic", "llm", "fallback"] = "deterministic"
    notes: List[str] = []


class LLMOp(BaseModel):
    kind: OpKind
    target: str = ""
    line: int = 0
    text: str = ""
    delta: Optional[int] = None


class LLMThread(BaseModel):
    id: str = Field(min_length=1)
    label: str = ""
    ops: List[LLMOp] = []


class LLMVisModel(BaseModel):
    threads: List[LLMThread]
    shared: List[SharedVar] = []
    locks: List[str] = []
