package com.bytebattle.ai.dto.feature;

public record AiInterviewEvaluateResponse(
        Double conceptualCorrectness,
        Double completeness,
        Double technicalClarity,
        Double reasoning,
        Double explanation,
        String feedback
) {}
