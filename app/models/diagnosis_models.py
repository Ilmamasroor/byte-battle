from pydantic import BaseModel
from typing import Optional
from typing import List

class DiagnosisRequest(BaseModel):
    userId: str
    activityType: str  # "battle", "interview", "coding", or "debugging"

    # Battle / Interview fields
    accuracy: Optional[float] = None
    score: Optional[float] = None
    attemptCount: Optional[int] = None
    timeSpentSeconds: Optional[int] = None

    # Coding / Debugging fields
    testCasesPassed: Optional[int] = None
    testCasesTotal: Optional[int] = None
    success: Optional[bool] = None

    # Common to all
    hintsUsed: int

class DiagnosisResponse(BaseModel):
    userId: str
    activityType: str
    conceptUnderstanding: Optional[float] = None
    decisionMaking: Optional[float] = None
    boundaryConditions: Optional[float] = None
    codingImplementation: Optional[float] = None
    hintDependency: Optional[float] = None


class AggregatedDiagnosisRequest(BaseModel):
    userId: str
    activities: List[DiagnosisRequest]

class AggregatedDiagnosisResponse(BaseModel):
    userId: str
    conceptUnderstanding: Optional[float] = None
    decisionMaking: Optional[float] = None
    boundaryConditions: Optional[float] = None
    codingImplementation: Optional[float] = None
    hintDependency: Optional[float] = None