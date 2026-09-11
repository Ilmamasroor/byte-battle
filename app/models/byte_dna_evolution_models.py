from pydantic import BaseModel
from typing import List, Dict, Optional

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

class ByteDNAEvolutionRequest(BaseModel):
    userId: str
    topic: str
    byteDNA: ByteDNASubset
    diagnosis: Optional[DiagnosisInput] = None
    performance: Optional[PerformanceInput] = None

class ByteDNAEvolutionResponse(BaseModel):
    userId: str
    byteDNA: ByteDNASubset