package com.bytebattle.ai.dto.personalization;

import java.util.List;
import java.util.Map;
import java.util.UUID;

public record ByteDnaAiResponse(
        UUID userId,
        String technicalExperience,
        String careerGoal,
        List<String> interests,
        String preferredLanguage,
        LearningPreferences learningPreferences,
        ExplanationPreferences explanationPreferences,
        List<String> confidenceAreas,
        List<String> difficultyAreas,
        List<String> repeatedMistakes,
        Map<String, Object> topicAccuracy,
        Map<String, Object> difficultyProgression
) {

    public record LearningPreferences(
            String learningStyle
    ) {}

    public record ExplanationPreferences(
            String explanationStyle
    ) {}
}
