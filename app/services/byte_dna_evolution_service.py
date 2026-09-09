from app.models.byte_dna_evolution_models import ByteDNAEvolutionRequest, ByteDNAEvolutionResponse, TopicAccuracyEntry

def evolve_byte_dna(request: ByteDNAEvolutionRequest) -> ByteDNAEvolutionResponse:
    updated_mistakes = list(request.currentRepeatedMistakes)
    if request.newErrorCategory:
        updated_mistakes.append(request.newErrorCategory)

    updated_accuracy = dict(request.currentTopicAccuracy)
    if request.newAccuracy is not None:
        existing = updated_accuracy.get(request.topic)

        if existing:
            total_correct = existing.averageAccuracy * existing.attemptCount
            new_count = existing.attemptCount + 1
            new_average = (total_correct + request.newAccuracy) / new_count
            updated_accuracy[request.topic] = TopicAccuracyEntry(
                averageAccuracy=round(new_average, 3),
                attemptCount=new_count
            )
        else:
            updated_accuracy[request.topic] = TopicAccuracyEntry(
                averageAccuracy=round(request.newAccuracy, 3),
                attemptCount=1
            )

    return ByteDNAEvolutionResponse(
        userId=request.userId,
        updatedRepeatedMistakes=updated_mistakes,
        updatedTopicAccuracy=updated_accuracy
    )