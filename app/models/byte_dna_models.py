from pydantic import BaseModel
from typing import List, Dict

class OnboardingRequest(BaseModel):
    userId: str
    educationStage: str
    programmingExperienceYears: float
    preferredLanguage: str
    careerGoal: str
    prefersVisual: bool
    prefersExamples: bool
    prefersProblemSolving: bool
    prefersAnalogies: bool
    prefersConcise: bool
    interests: List[str]

class LearningPreferences(BaseModel):
    visual: bool
    examples: bool
    problemSolving: bool
    analogies: bool
    detailLevel: str

class ByteDNA(BaseModel):
    userId: str
    technicalExperience: str
    careerGoal: str
    interests: List[str]
    preferredLanguage: str
    learningPreferences: LearningPreferences
    confidenceAreas: List[str] = []
    difficultyAreas: List[str] = []
    explanationPreferences: Dict = {}
    repeatedMistakes: List[str] = []
    topicAccuracy: Dict = {}
    difficultyProgression: Dict = {}