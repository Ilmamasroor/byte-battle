from pydantic import BaseModel
from typing import List, Optional

class RecommendationRequest(BaseModel):
    userId: str
    technicalExperience: str
    topic: Optional[str] = None
    repeatedMistakes: List[str] = []
    conceptUnderstanding: Optional[float] = None
    decisionMaking: Optional[float] = None
    boundaryConditions: Optional[float] = None
    codingImplementation: Optional[float] = None
    hintDependency: Optional[float] = None

class RecommendationResponse(BaseModel):
    userId: str
    topic: Optional[str] = None
    targetErrorCategory: Optional[str] = None
    recommendedChallengeType: str
    reason: str
    basis: str