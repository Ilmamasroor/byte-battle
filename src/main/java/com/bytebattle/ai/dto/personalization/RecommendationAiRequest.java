package com.bytebattle.ai.dto.personalization;

import java.util.List;
import java.util.UUID;

public record RecommendationAiRequest(
        UUID userId,
        String technicalExperience,
        String topic,
        List<String> repeatedMistakes,
        Double conceptUnderstanding,
        Double decisionMaking,
        Double boundaryConditions,
        Double codingImplementation,
        Double hintDependency
) {
    /** Returns a copy bound to the authenticated user; client-supplied userId must never be trusted. */
    public RecommendationAiRequest withUserId(UUID userId) {
        return new RecommendationAiRequest(userId, technicalExperience, topic, repeatedMistakes, conceptUnderstanding, decisionMaking, boundaryConditions, codingImplementation, hintDependency);
    }
}
