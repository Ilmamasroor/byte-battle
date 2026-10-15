from app.models.byte_dna_models import (
    OnboardingRequest, ByteDNA, LearningPreferences, ExplanationPreferences
)

def create_byte_dna(data: OnboardingRequest) -> ByteDNA:
    learning_preferences = LearningPreferences(learningStyle=data.learningStyle)
    explanation_preferences = ExplanationPreferences(explanationStyle=data.explanationStyle)

    return ByteDNA(
        userId=data.userId,
        technicalExperience=data.technicalExperience,
        careerGoal=data.careerGoal,
        interests=data.interests,
        preferredLanguage=data.preferredLanguage,
        learningPreferences=learning_preferences,
        explanationPreferences=explanation_preferences
    )