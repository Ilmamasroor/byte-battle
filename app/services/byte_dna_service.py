from app.models.byte_dna_models import OnboardingRequest, ByteDNA, LearningPreferences

def determine_experience_level(years: float) -> str:
    if years < 1:
        return "BEGINNER"
    elif years < 3:
        return "INTERMEDIATE"
    else:
        return "ADVANCED"

def create_byte_dna(data: OnboardingRequest) -> ByteDNA:
    technical_experience = determine_experience_level(data.programmingExperienceYears)

    preferences = LearningPreferences(
        visual=data.prefersVisual,
        examples=data.prefersExamples,
        problemSolving=data.prefersProblemSolving,
        analogies=data.prefersAnalogies,
        detailLevel="concise" if data.prefersConcise else "detailed"
    )

    return ByteDNA(
        userId=data.userId,
        technicalExperience=technical_experience,
        careerGoal=data.careerGoal,
        interests=data.interests,
        preferredLanguage=data.preferredLanguage,
        learningPreferences=preferences
    )