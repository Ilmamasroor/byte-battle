from app.core.config import settings
from app.models.byte_dna_evolution_models import (
    DIMENSIONS,
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

EVIDENCE_DIMENSION = {
    "BATTLE": "understanding",
    "CODE": "application",
    "DEBUG": "debugging",
    "EXPLAIN": "technicalCommunication",
    "INTERVIEW": "technicalCommunication",
}
DEFAULT_BASELINE = 0.5
MAX_REPEATED_MISTAKES = 20


def _clamp01(v: float) -> float:
    return max(0.0, min(1.0, float(v)))


def blend_dimension(previous: float, new: float, weight_previous: float | None = None) -> float:
    """Updated = previous * w + new * (1 - w); w defaults to BYTE_DNA_WEIGHT_PREVIOUS (0.7)."""
    w = settings.byte_dna_weight_previous if weight_previous is None else weight_previous
    return _clamp01(previous * w + new * (1.0 - w))


def _baseline_for(request: ByteDNAEvolutionRequest, dimension: str) -> float:
    b = request.baseline
    if isinstance(b, dict):
        return _clamp01(b.get(dimension, DEFAULT_BASELINE))
    if b is not None:
        return _clamp01(b)
    return DEFAULT_BASELINE


def evolve_dimensions(request: ByteDNAEvolutionRequest):
    """Asynchronous model: only the dimension the evidence maps to is updated."""
    previous = {k: _clamp01(v) for k, v in (request.dimensionScores or {}).items() if k in DIMENSIONS and v is not None}
    counts = {d: max(0, int((request.dimensionEvidenceCount or {}).get(d, 0))) for d in DIMENSIONS}
    scores = {}
    for d in DIMENSIONS:
        scores[d] = previous.get(d, _baseline_for(request, d))
    if request.evidence is not None:
        dim = EVIDENCE_DIMENSION[request.evidence.type]
        # first evidence with no previous value: blend with the baseline
        base = previous.get(dim, _baseline_for(request, dim))
        scores[dim] = blend_dimension(base, request.evidence.score)
        counts[dim] += 1
    return {d: round(v, 4) for d, v in scores.items()}, counts


def _cap_mistakes(mistakes):
    """Unique, most-recent 20, returned oldest -> newest."""
    seen, newest_first = set(), []
    for m in reversed([m for m in mistakes if m]):
        if m not in seen:
            seen.add(m)
            newest_first.append(m)
    return list(reversed(newest_first[:MAX_REPEATED_MISTAKES]))


def evolve_byte_dna(request: ByteDNAEvolutionRequest) -> ByteDNAEvolutionResponse:
    new_error_category = request.diagnosis.errorCategory if request.diagnosis else None
    new_accuracy = request.performance.accuracy if request.performance else None
    canonical_topic = request.topic.strip().lower().replace(" ", "_")

    # --- repeatedMistakes ---
    updated_mistakes = list(request.byteDNA.repeatedMistakes)
    if new_error_category:
        updated_mistakes.append(new_error_category)
    updated_mistakes = _cap_mistakes(updated_mistakes)

    # --- topicAccuracy ---
    updated_accuracy = dict(request.byteDNA.topicAccuracy)
    if new_accuracy is not None:
        existing = updated_accuracy.get(canonical_topic)
        if existing:
            total_correct = existing.averageAccuracy * existing.attemptCount
            new_count = existing.attemptCount + 1
            new_average = (total_correct + new_accuracy) / new_count
            updated_accuracy[canonical_topic] = TopicAccuracyEntry(
                averageAccuracy=round(new_average, 3),
                attemptCount=new_count
            )
        else:
            updated_accuracy[canonical_topic] = TopicAccuracyEntry(
                averageAccuracy=round(new_accuracy, 3),
                attemptCount=1
            )

    # --- difficultyProgression ---
    updated_progression = dict(request.byteDNA.difficultyProgression)
    if new_accuracy is not None:
        default_difficulty = EXPERIENCE_TO_DIFFICULTY.get(request.byteDNA.technicalExperience, "EASY")
        entry = updated_progression.get(
            canonical_topic,
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

        if current_difficulty not in DIFFICULTY_LEVELS:
            current_difficulty = default_difficulty
        idx = DIFFICULTY_LEVELS.index(current_difficulty)

        if successes >= STREAK_TO_ADVANCE and idx < len(DIFFICULTY_LEVELS) - 1:
            current_difficulty = DIFFICULTY_LEVELS[idx + 1]
            successes = 0
        elif failures >= STREAK_TO_ADVANCE and idx > 0:
            current_difficulty = DIFFICULTY_LEVELS[idx - 1]
            failures = 0

        updated_progression[canonical_topic] = DifficultyProgressionEntry(
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

    dimension_scores, dimension_counts = evolve_dimensions(request)
    return ByteDNAEvolutionResponse(
        userId=request.userId,
        byteDNA=updated_byte_dna,
        dimensionScores=dimension_scores,
        dimensionEvidenceCount=dimension_counts,
    )
