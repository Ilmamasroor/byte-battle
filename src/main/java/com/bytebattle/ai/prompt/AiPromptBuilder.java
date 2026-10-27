package com.bytebattle.ai.prompt;


import com.bytebattle.ai.dto.AiRequest;
import com.bytebattle.bytedna.ByteDNA;
import com.bytebattle.bytedna.ByteDNARepository;
import com.bytebattle.curriculum.Concept;
import com.bytebattle.curriculum.ConceptRepository;
import com.bytebattle.exception.ResourceNotFoundException;
import com.bytebattle.performance.dto.PerformanceSummaryResponse;
import com.bytebattle.performance.service.PerformanceService;
import org.springframework.stereotype.Component;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Component
public class AiPromptBuilder {

    private final PerformanceService performanceService;
    private final ConceptRepository conceptRepository;
    private final ByteDNARepository byteDNARepository;

    public AiPromptBuilder(PerformanceService performanceService,
                           ConceptRepository conceptRepository,
                           ByteDNARepository byteDNARepository) {
        this.performanceService = performanceService;
        this.conceptRepository = conceptRepository;
        this.byteDNARepository = byteDNARepository;
    }

    /**
     * Builds the shared AiRequest envelope from real data: the concept and its topic come from the
     * curriculum, byteDNA is the learner's stored profile (safe beginner defaults before onboarding),
     * and performance is the learner's aggregated evidence.
     *
     * canonicalKnowledge is left empty on purpose: the AI service then grounds the answer in its
     * curated content index for this concept instead of trusting free generation.
     */
    public AiRequest.AiRequestBuilder baseRequest(String operation, UUID userId, UUID conceptId) {
        Concept concept = conceptRepository.findById(conceptId)
                .orElseThrow(() -> new ResourceNotFoundException("Concept not found: " + conceptId));
        PerformanceSummaryResponse summary = performanceService.getSummary(userId);

        return AiRequest.builder()
                .operation(operation)
                .userId(userId)
                .concept(AiRequest.ConceptInfo.builder()
                        .conceptId(concept.getId())
                        .topic(concept.getTopic() != null ? concept.getTopic().getName() : null)
                        .conceptName(concept.getName())
                        .difficulty(concept.getDifficulty() != null ? concept.getDifficulty().name() : "MEDIUM")
                        .build())
                .canonicalKnowledge(AiRequest.CanonicalKnowledge.builder()
                        .keyPoints(List.of())
                        .rules(List.of())
                        .examples(List.of())
                        .build())
                .byteDNA(byteDnaInfo(userId))
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
        // .diagnosis(...) intentionally left unset here: only DiagnosisService fills it in
    }

    private AiRequest.ByteDnaInfo byteDnaInfo(UUID userId) {
        ByteDNA dna = byteDNARepository.findByUser_Id(userId).orElse(null);
        if (dna == null) {
            return AiRequest.ByteDnaInfo.builder()
                    .technicalExperience("BEGINNER")
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
                    .build();
        }
        return AiRequest.ByteDnaInfo.builder()
                .technicalExperience(dna.getTechnicalExperience() != null ? dna.getTechnicalExperience().name() : "BEGINNER")
                .careerGoal(dna.getCareerGoal() != null ? dna.getCareerGoal() : "")
                .interests(orEmpty(dna.getInterests()))
                .preferredLanguage(dna.getPreferredLanguage() != null ? dna.getPreferredLanguage() : "JAVA")
                .learningPreferences(style(dna.getLearningPreferences() != null ? dna.getLearningPreferences().name() : null))
                .confidenceAreas(orEmpty(dna.getConfidenceAreas()))
                .difficultyAreas(orEmpty(dna.getDifficultyAreas()))
                .explanationPreferences(style(dna.getExplanationPreferences() != null ? dna.getExplanationPreferences().name() : null))
                .repeatedMistakes(orEmpty(dna.getRepeatedMistakes()))
                .topicAccuracy(numericOnly(dna.getTopicAccuracy()))
                .difficultyProgression(dna.getDifficultyProgression() != null ? dna.getDifficultyProgression() : Map.of())
                .build();
    }

    private static List<String> orEmpty(List<String> list) {
        return list != null ? list : List.of();
    }

    private static Map<String, Object> style(String value) {
        return value == null ? Map.of() : Map.of("style", value);
    }

    /** The AI contract needs Map<String, Double>; the stored JSON may hold any number type. */
    private static Map<String, Double> numericOnly(Map<String, Object> raw) {
        Map<String, Double> out = new HashMap<>();
        if (raw != null) {
            raw.forEach((k, v) -> {
                if (v instanceof Number n) {
                    out.put(k, n.doubleValue());
                }
            });
        }
        return out;
    }
}
