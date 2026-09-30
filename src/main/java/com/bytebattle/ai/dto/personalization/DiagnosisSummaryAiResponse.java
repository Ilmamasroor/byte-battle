package com.bytebattle.ai.dto.personalization;

public record DiagnosisSummaryAiResponse(
        Double conceptUnderstanding,
        Double decisionMaking,
        Double boundaryConditions,
        Double codingImplementation,
        Double hintDependency
) {}
