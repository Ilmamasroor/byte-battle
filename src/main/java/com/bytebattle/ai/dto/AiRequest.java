package com.bytebattle.ai.dto;


import lombok.Builder;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@Builder
public record AiRequest(
        String operation,
        UUID userId,
        ConceptInfo concept,
        CanonicalKnowledge canonicalKnowledge,
        ByteDnaInfo byteDNA,
        PerformanceInfo performance,
        LearningHistoryInfo learningHistory,
        DiagnosisInfo diagnosis
) {
    @Builder
    public record ConceptInfo(
            UUID conceptId, String topic, String conceptName, String difficulty
    ) {}

    @Builder
    public record CanonicalKnowledge(
            List<String> keyPoints, List<String> rules, List<String> examples
    ) {}

    @Builder
    public record ByteDnaInfo(
            String technicalExperience, String careerGoal, List<String> interests,
            String preferredLanguage, Map<String, Object> learningPreferences,
            List<String> confidenceAreas, List<String> difficultyAreas,
            Map<String, Object> explanationPreferences, List<String> repeatedMistakes,
            Map<String, Double> topicAccuracy, Map<String, Object> difficultyProgression
    ) {}

    @Builder
    public record PerformanceInfo(
            Integer score, Double accuracy, Integer timeSpentSeconds,
            Integer attemptCount, Boolean success, Integer hintsUsed
    ) {}

    @Builder
    public record LearningHistoryInfo(
            List<String> completedStages, String currentStage, List<String> previousPerformance
    ) {}

    @Builder
    public record DiagnosisInfo(
            String activityType, String errorCategory, String errorMessage,
            String sourceCode, String executionStatus, Integer executionTimeMs,
            Integer testCasesPassed, Integer testCasesTotal
    ) {}
}