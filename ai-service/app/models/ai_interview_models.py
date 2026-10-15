from typing import Any, Dict, List, Optional

from pydantic import BaseModel, Field

from app.models.llm_response import LLMResponse


class AIInterviewQuestionRequest(BaseModel):
    concept: Dict[str, Any] = {}
    canonicalKnowledge: Dict[str, Any] = {}
    conversationHistory: List[Any] = []


class AIInterviewQuestionResponse(LLMResponse):
    question: str = Field(min_length=1)


class RubricItem(BaseModel):
    id: str = Field(min_length=1)
    description: str = Field(min_length=1)
    # optional: which of the five legacy score fields this item feeds
    dimension: Optional[str] = None


class AIInterviewEvaluateRequest(BaseModel):
    concept: Dict[str, Any] = {}
    canonicalKnowledge: Dict[str, Any] = {}
    question: str = ""
    learnerAnswer: str = ""
    rubric: Optional[List[RubricItem]] = None


class RubricResult(BaseModel):
    id: str
    met: bool
    evidence: str = ""
    description: Optional[str] = None


class AIInterviewEvaluateResponse(LLMResponse):
    conceptualCorrectness: float = Field(ge=0.0, le=1.0)
    completeness: float = Field(ge=0.0, le=1.0)
    technicalClarity: float = Field(ge=0.0, le=1.0)
    reasoning: float = Field(ge=0.0, le=1.0)
    explanation: float = Field(ge=0.0, le=1.0)
    feedback: str = Field(min_length=1)
    rubricResults: Optional[List[RubricResult]] = None


# Raw shape the LLM must return for rubric evaluation
class LLMRubricItem(BaseModel):
    id: str
    met: bool = False
    evidence: str = ""


class LLMRubricEvaluation(LLMResponse):
    results: List[LLMRubricItem]
    feedback: str = ""
