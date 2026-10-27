package com.bytebattle.ai.dto.personalization;

import java.util.List;
import java.util.Map;
import java.util.UUID;

public record ByteDnaEvolutionResponse(
        UUID userId,
        ByteDna byteDNA
) {

    public record ByteDna(
            String technicalExperience,
            List<String> repeatedMistakes,
            Map<String, Object> topicAccuracy,
            List<String> confidenceAreas,
            List<String> difficultyAreas,
            Map<String, Object> difficultyProgression
    ) {}
}
