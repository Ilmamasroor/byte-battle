from typing import Any, Dict, List

from pydantic import BaseModel, Field

from app.models.llm_response import LLMResponse


class AIInterviewQuestionRequest(BaseModel):
    concept: Dict[str, Any] = {}
    canonicalKnowledge: Dict[str, Any] = {}
    conversationHistory: List[Any] = []


class AIInterviewQuestionResponse(LLMResponse):
    question: str = Field(min_length=1)


class AIInterviewEvaluateRequest(BaseModel):
    concept: Dict[str, Any] = {}
    canonicalKnowledge: Dict[str, Any] = {}
    question: str = ""
    learnerAnswer: str = ""


class AIInterviewEvaluateResponse(LLMResponse):
    conceptualCorrectness: float = Field(ge=0.0, le=1.0)
    completeness: float = Field(ge=0.0, le=1.0)
    technicalClarity: float = Field(ge=0.0, le=1.0)
    reasoning: float = Field(ge=0.0, le=1.0)
    explanation: float = Field(ge=0.0, le=1.0)
    feedback: str = Field(min_length=1)
