from typing import Any, Dict, List
from pydantic import BaseModel


class InterviewQuestionRequest(BaseModel):
    concept: Dict[str, Any] = {}
    canonicalKnowledge: Dict[str, Any] = {}
    conversationHistory: List[Any] = []


class InterviewQuestionResponse(BaseModel):
    question: str


class InterviewEvaluateRequest(BaseModel):
    concept: Dict[str, Any] = {}
    canonicalKnowledge: Dict[str, Any] = {}
    question: str = ""
    learnerAnswer: str = ""


class InterviewEvaluateResponse(BaseModel):
    conceptualCorrectness: float
    completeness: float
    technicalClarity: float
    reasoning: float
    explanation: float
    feedback: str
