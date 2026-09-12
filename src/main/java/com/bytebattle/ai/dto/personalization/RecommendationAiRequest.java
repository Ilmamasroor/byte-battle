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
) {}
