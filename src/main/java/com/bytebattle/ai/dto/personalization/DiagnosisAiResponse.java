package com.bytebattle.ai.dto.personalization;

import java.util.UUID;

public record DiagnosisAiResponse(
        UUID userId,
        String activityType,
        Double conceptUnderstanding,
        Double decisionMaking,
        Double boundaryConditions,
        Double codingImplementation,
        Double hintDependency
) {}
