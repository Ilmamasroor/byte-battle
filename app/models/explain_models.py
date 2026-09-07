from pydantic import BaseModel

class ExplainRequest(BaseModel):
    concept: str