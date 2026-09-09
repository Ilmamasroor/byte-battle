from pydantic import BaseModel
from typing import List, Optional

class RecommendationRequest(BaseModel):
    userId: str
    topic: str
    repeatedMistakes: List[str] = []
    conceptUnderstanding: Optional[float] = None
    decisionMaking: Optional[float] = None
    boundaryConditions: Optional[float] = None
    codingImplementation: Optional[float] = None
    hintDependency: Optional[float] = None

class RecommendationResponse(BaseModel):
    userId: str
    topic: str
    targetErrorCategory: Optional[str] = None
    recommendedChallengeType: str
    reason: str
    basis: str