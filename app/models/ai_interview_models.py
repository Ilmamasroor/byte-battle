from typing import Any, Dict, List

from pydantic import BaseModel


class AIInterviewQuestionRequest(BaseModel):
    concept: Dict[str, Any] = {}
    canonicalKnowledge: Dict[str, Any] = {}
    conversationHistory: List[Any] = []


class AIInterviewQuestionResponse(BaseModel):
    question: str


class AIInterviewEvaluateRequest(BaseModel):
    concept: Dict[str, Any] = {}
    canonicalKnowledge: Dict[str, Any] = {}
    question: str = ""
    learnerAnswer: str = ""


class AIInterviewEvaluateResponse(BaseModel):
    conceptualCorrectness: float
    completeness: float
    technicalClarity: float
    reasoning: float
    explanation: float
    feedback: str
