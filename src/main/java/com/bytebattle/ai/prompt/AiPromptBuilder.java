package com.bytebattle.ai.prompt;


import com.bytebattle.ai.dto.AiRequest;
import com.bytebattle.performance.dto.PerformanceSummaryResponse;
import com.bytebattle.performance.service.PerformanceService;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@Component
public class AiPromptBuilder {

    private final PerformanceService performanceService;

    public AiPromptBuilder(PerformanceService performanceService) {
        this.performanceService = performanceService;
    }

    /**
     * Builds the shared AiRequest envelope. Concept/canonicalKnowledge come from
     * Developer 1's curriculum data (not yet available while running standalone —
     * pass placeholders for now, wire in real values once merged). byteDNA is
     * entirely Developer 1's territory (doc §31) — left as safe defaults until
     * that entity exists on your side. Performance is real, pulled from your
     * own PerformanceService right now.
     */
    public AiRequest.AiRequestBuilder baseRequest(String operation, UUID userId, UUID conceptId) {
        PerformanceSummaryResponse summary = performanceService.getSummary(userId);

        return AiRequest.builder()
                .operation(operation)
                .userId(userId)
                .concept(AiRequest.ConceptInfo.builder()
                        .conceptId(conceptId)
                        .topic("UNKNOWN")          // TODO: replace with Developer 1's curriculum lookup
                        .conceptName("UNKNOWN")
                        .difficulty("MEDIUM")
                        .build())
                .canonicalKnowledge(AiRequest.CanonicalKnowledge.builder()
                        .keyPoints(List.of())
                        .rules(List.of())
                        .examples(List.of())
                        .build())
                .byteDNA(AiRequest.ByteDnaInfo.builder()
                        .technicalExperience("BEGINNER")   // TODO: pull from Developer 1's ByteDNA once merged
                        .careerGoal("")
                        .interests(List.of())
                        .preferredLanguage("JAVA")
                        .learningPreferences(Map.of())
                        .confidenceAreas(List.of())
                        .difficultyAreas(List.of())
                        .explanationPreferences(Map.of())
                        .repeatedMistakes(List.of())
                        .topicAccuracy(Map.of())
                        .difficultyProgression(Map.of())
                        .build())
                .performance(AiRequest.PerformanceInfo.builder()
                        .score((int) Math.round(summary.averageScore()))
                        .accuracy(summary.averageAccuracy())
                        .timeSpentSeconds(0)
                        .attemptCount(summary.totalActivities())
                        .success(summary.successRate() >= 0.5)
                        .hintsUsed(0)
                        .build())
                .learningHistory(AiRequest.LearningHistoryInfo.builder()
                        .completedStages(List.of())
                        .currentStage("")
                        .previousPerformance(List.of())
                        .build());
        // .diagnosis(...) intentionally left unset here — only DiagnosisService fills it in
    }
}