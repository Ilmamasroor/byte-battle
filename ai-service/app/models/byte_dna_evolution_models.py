from pydantic import BaseModel
from typing import List, Dict, Optional, Union
from typing import Literal
from pydantic import Field

class TopicAccuracyEntry(BaseModel):
    averageAccuracy: float
    attemptCount: int

class DifficultyProgressionEntry(BaseModel):
    currentDifficulty: str
    consecutiveSuccesses: int
    consecutiveFailures: int

class ByteDNASubset(BaseModel):
    technicalExperience: Optional[str] = None
    repeatedMistakes: List[str] = []
    topicAccuracy: Dict[str, TopicAccuracyEntry] = {}
    confidenceAreas: List[str] = []
    difficultyAreas: List[str] = []
    difficultyProgression: Dict[str, DifficultyProgressionEntry] = {}

class DiagnosisInput(BaseModel):
    errorCategory: Optional[str] = None

class PerformanceInput(BaseModel):
    accuracy: Optional[float] = None

DIMENSIONS = ["understanding", "application", "debugging", "technicalCommunication"]


class Evidence(BaseModel):
    type: Literal["BATTLE", "CODE", "DEBUG", "EXPLAIN", "INTERVIEW"]
    score: float = Field(ge=0.0, le=1.0)


class ByteDNAEvolutionRequest(BaseModel):
    userId: str
    topic: str
    byteDNA: ByteDNASubset
    diagnosis: Optional[DiagnosisInput] = None
    performance: Optional[PerformanceInput] = None
    # previous per-dimension scores (0..1) for understanding/application/debugging/technicalCommunication
    dimensionScores: Optional[Dict[str, float]] = None
    # previous evidence counts per dimension
    dimensionEvidenceCount: Optional[Dict[str, int]] = None
    # one new piece of evidence; maps to exactly one dimension
    evidence: Optional[Evidence] = None
    # onboarding baseline: a single float or a per-dimension map (default 0.5)
    baseline: Optional[Union[float, Dict[str, float]]] = None

class ByteDNAEvolutionResponse(BaseModel):
    userId: str
    byteDNA: ByteDNASubset
    dimensionScores: Dict[str, float] = {}
    dimensionEvidenceCount: Dict[str, int] = {}