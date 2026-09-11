from app.models.byte_dna_evolution_models import (
    ByteDNAEvolutionRequest, ByteDNAEvolutionResponse, ByteDNASubset,
    TopicAccuracyEntry, DifficultyProgressionEntry
)

MIN_ATTEMPTS = 3
CONFIDENCE_THRESHOLD = 0.75
DIFFICULTY_THRESHOLD = 0.5
DIFFICULTY_LEVELS = ["EASY", "MEDIUM", "HARD"]
SUCCESS_THRESHOLD = 0.75
STREAK_TO_ADVANCE = 3
EXPERIENCE_TO_DIFFICULTY = {
    "BEGINNER": "EASY",
    "INTERMEDIATE": "MEDIUM",
    "ADVANCED": "HARD",
}

def evolve_byte_dna(request: ByteDNAEvolutionRequest) -> ByteDNAEvolutionResponse:
    new_error_category = request.diagnosis.errorCategory if request.diagnosis else None
    new_accuracy = request.performance.accuracy if request.performance else None

    # --- repeatedMistakes ---
    updated_mistakes = list(request.byteDNA.repeatedMistakes)
    if new_error_category:
        updated_mistakes.append(new_error_category)

    # --- topicAccuracy ---
    updated_accuracy = dict(request.byteDNA.topicAccuracy)
    if new_accuracy is not None:
        existing = updated_accuracy.get(request.topic)
        if existing:
            total_correct = existing.averageAccuracy * existing.attemptCount
            new_count = existing.attemptCount + 1
            new_average = (total_correct + new_accuracy) / new_count
            updated_accuracy[request.topic] = TopicAccuracyEntry(
                averageAccuracy=round(new_average, 3),
                attemptCount=new_count
            )
        else:
            updated_accuracy[request.topic] = TopicAccuracyEntry(
                averageAccuracy=round(new_accuracy, 3),
                attemptCount=1
            )

    # --- difficultyProgression ---
    updated_progression = dict(request.byteDNA.difficultyProgression)
    if new_accuracy is not None:
        default_difficulty = EXPERIENCE_TO_DIFFICULTY.get(request.byteDNA.technicalExperience, "EASY")
        entry = updated_progression.get(
            request.topic,
            DifficultyProgressionEntry(
                currentDifficulty=default_difficulty,
                consecutiveSuccesses=0,
                consecutiveFailures=0
            )
        )

        current_difficulty = entry.currentDifficulty
        successes = entry.consecutiveSuccesses
        failures = entry.consecutiveFailures

        if new_accuracy >= SUCCESS_THRESHOLD:
            successes += 1
            failures = 0
        else:
            failures += 1
            successes = 0

        idx = DIFFICULTY_LEVELS.index(current_difficulty)

        if successes >= STREAK_TO_ADVANCE and idx < len(DIFFICULTY_LEVELS) - 1:
            current_difficulty = DIFFICULTY_LEVELS[idx + 1]
            successes = 0
        elif failures >= STREAK_TO_ADVANCE and idx > 0:
            current_difficulty = DIFFICULTY_LEVELS[idx - 1]
            failures = 0

        updated_progression[request.topic] = DifficultyProgressionEntry(
            currentDifficulty=current_difficulty,
            consecutiveSuccesses=successes,
            consecutiveFailures=failures
        )

    # --- confidenceAreas / difficultyAreas ---
    confidence_set = set(request.byteDNA.confidenceAreas)
    difficulty_set = set(request.byteDNA.difficultyAreas)

    for topic, accuracy_data in updated_accuracy.items():
        if accuracy_data.attemptCount < MIN_ATTEMPTS:
            continue
        confidence_set.discard(topic)
        difficulty_set.discard(topic)
        if accuracy_data.averageAccuracy >= CONFIDENCE_THRESHOLD:
            confidence_set.add(topic)
        elif accuracy_data.averageAccuracy < DIFFICULTY_THRESHOLD:
            difficulty_set.add(topic)

    updated_byte_dna = ByteDNASubset(
        technicalExperience=request.byteDNA.technicalExperience,
        repeatedMistakes=updated_mistakes,
        topicAccuracy=updated_accuracy,
        confidenceAreas=sorted(confidence_set),
        difficultyAreas=sorted(difficulty_set),
        difficultyProgression=updated_progression
    )

    return ByteDNAEvolutionResponse(userId=request.userId, byteDNA=updated_byte_dna)