"""Mirror of Java com.bytebattle.ai.dto.AiRequest / AiResponse (camelCase JSON)."""
from typing import Any, Dict, List, Optional

from pydantic import BaseModel


class ConceptInfo(BaseModel):
    conceptId: Optional[str] = None
    topic: Optional[str] = None
    conceptName: Optional[str] = None
    difficulty: Optional[str] = None


class CanonicalKnowledgeInfo(BaseModel):
    keyPoints: Optional[List[str]] = None
    rules: Optional[List[str]] = None
    examples: Optional[List[str]] = None


class ByteDnaInfo(BaseModel):
    technicalExperience: Optional[str] = None
    careerGoal: Optional[str] = None
    interests: Optional[List[str]] = None
    preferredLanguage: Optional[str] = None
    learningPreferences: Optional[Dict[str, Any]] = None
    confidenceAreas: Optional[List[str]] = None
    difficultyAreas: Optional[List[str]] = None
    explanationPreferences: Optional[Dict[str, Any]] = None
    repeatedMistakes: Optional[List[str]] = None
    topicAccuracy: Optional[Dict[str, float]] = None
    difficultyProgression: Optional[Dict[str, Any]] = None


class PerformanceInfo(BaseModel):
    score: Optional[float] = None
    accuracy: Optional[float] = None
    timeSpentSeconds: Optional[int] = None
    attemptCount: Optional[int] = None
    success: Optional[bool] = None
    hintsUsed: Optional[int] = 0


class LearningHistoryInfo(BaseModel):
    completedStages: Optional[List[str]] = None
    currentStage: Optional[str] = None
    previousPerformance: Optional[List[str]] = None


class DiagnosisInfo(BaseModel):
    activityType: Optional[str] = None
    errorCategory: Optional[str] = None
    errorMessage: Optional[str] = None
    sourceCode: Optional[str] = None
    executionStatus: Optional[str] = None
    executionTimeMs: Optional[int] = None
    testCasesPassed: Optional[int] = None
    testCasesTotal: Optional[int] = None


class AiRequest(BaseModel):
    operation: Optional[str] = None
    userId: Optional[str] = None
    concept: Optional[ConceptInfo] = None
    canonicalKnowledge: Optional[CanonicalKnowledgeInfo] = None
    byteDNA: Optional[ByteDnaInfo] = None
    performance: Optional[PerformanceInfo] = None
    learningHistory: Optional[LearningHistoryInfo] = None
    diagnosis: Optional[DiagnosisInfo] = None


class AiResponse(BaseModel):
    success: bool
    operation: Optional[str] = None
    content: Optional[str] = None
    metadata: Dict[str, Any] = {}
