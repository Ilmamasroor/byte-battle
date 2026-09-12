from pydantic import BaseModel


class ExplainRequest(BaseModel):
    concept: str


class ExplainResponse(BaseModel):
    concept: str
    explanation: str
