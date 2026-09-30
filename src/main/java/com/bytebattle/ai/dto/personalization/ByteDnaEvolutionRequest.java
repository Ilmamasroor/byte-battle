package com.bytebattle.ai.dto.personalization;

import java.util.List;
import java.util.Map;
import java.util.UUID;

public record ByteDnaEvolutionRequest(
        UUID userId,
        String topic,
        ByteDna byteDNA,
        Diagnosis diagnosis,
        Performance performance
) {

    public record Diagnosis(
            String errorCategory
    ) {}

    public record Performance(
            Double accuracy
    ) {}

    public record ByteDna(
            String technicalExperience,
            List<String> repeatedMistakes,
            Map<String, Object> topicAccuracy,
            List<String> confidenceAreas,
            List<String> difficultyAreas,
            Map<String, Object> difficultyProgression
    ) {}
}
