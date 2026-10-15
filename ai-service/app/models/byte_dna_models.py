from pydantic import BaseModel
from typing import List, Dict

class OnboardingRequest(BaseModel):
    userId: str
    technicalExperience: str
    preferredLanguage: str
    careerGoal: str
    learningStyle: str
    explanationStyle: str
    interests: List[str]

class LearningPreferences(BaseModel):
    learningStyle: str

class ExplanationPreferences(BaseModel):
    explanationStyle: str

class ByteDNA(BaseModel):
    userId: str
    technicalExperience: str
    careerGoal: str
    interests: List[str]
    preferredLanguage: str
    learningPreferences: LearningPreferences
    explanationPreferences: ExplanationPreferences
    confidenceAreas: List[str] = []
    difficultyAreas: List[str] = []
    repeatedMistakes: List[str] = []
    topicAccuracy: Dict = {}
    difficultyProgression: Dict = {}