from pydantic import BaseModel
from typing import List, Optional

class InterviewQuestionRequest(BaseModel):
    userId: str
    topic: str
    difficulty: str
    excludedIds: List[str] = []

class InterviewQuestionResponse(BaseModel):
    userId: str
    questionId: Optional[str] = None
    question: Optional[str] = None
    difficulty: Optional[str] = None
    subCategory: Optional[str] = None
    message: Optional[str] = None