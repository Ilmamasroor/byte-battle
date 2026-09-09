from pydantic import BaseModel
from typing import List, Dict, Optional

class TopicAccuracyEntry(BaseModel):
    averageAccuracy: float
    attemptCount: int

class ByteDNAEvolutionRequest(BaseModel):
    userId: str
    topic: str
    currentRepeatedMistakes: List[str] = []
    currentTopicAccuracy: Dict[str, TopicAccuracyEntry] = {}
    newErrorCategory: Optional[str] = None
    newAccuracy: Optional[float] = None

class ByteDNAEvolutionResponse(BaseModel):
    userId: str
    updatedRepeatedMistakes: List[str]
    updatedTopicAccuracy: Dict[str, TopicAccuracyEntry]