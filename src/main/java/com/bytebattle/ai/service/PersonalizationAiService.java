package com.bytebattle.ai.service;

import com.bytebattle.ai.client.PersonalizationAiClient;
import com.bytebattle.ai.dto.personalization.*;
import com.bytebattle.bytedna.ByteDNA;
import com.bytebattle.bytedna.ByteDNARepository;
import com.bytebattle.curriculum.Concept;
import com.bytebattle.recommendation.dto.CreateRecommendationRequest;
import com.bytebattle.recommendation.enums.RecommendationPriority;
import com.bytebattle.recommendation.enums.RecommendationSource;
import com.bytebattle.recommendation.enums.RecommendationType;
import com.bytebattle.recommendation.service.RecommendationService;
import com.bytebattle.user.User;
import com.bytebattle.user.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class PersonalizationAiService {

    private final PersonalizationAiClient aiClient;
    private final ByteDNARepository byteDNARepository;
    private final UserRepository userRepository;
    private final AiCurriculumResolver curriculumResolver;
    private final RecommendationService recommendationService;

    public PersonalizationAiService(
            PersonalizationAiClient aiClient,
            ByteDNARepository byteDNARepository,
            UserRepository userRepository,
            AiCurriculumResolver curriculumResolver,
            RecommendationService recommendationService) {

        this.aiClient = aiClient;
        this.byteDNARepository = byteDNARepository;
        this.userRepository = userRepository;
        this.curriculumResolver = curriculumResolver;
        this.recommendationService = recommendationService;
    }

    @Transactional
    public ByteDnaAiResponse onboard(OnboardingAiRequest request) {

        ByteDnaAiResponse response = aiClient.onboard(request);

        User user = userRepository.findById(request.userId())
                .orElseThrow(() ->
                        new IllegalArgumentException("User not found: " + request.userId()));

        ByteDNA dna = byteDNARepository.findByUser_Id(request.userId())
                .orElseGet(() -> {
                    ByteDNA newDna = new ByteDNA();
                    newDna.setUser(user);
                    return newDna;
                });

        dna.setTechnicalExperience(
                parseTechnicalExperience(response.technicalExperience())
        );
        dna.setCareerGoal(response.careerGoal());
        dna.setInterests(response.interests());
        dna.setPreferredLanguage(response.preferredLanguage());

        if (response.learningPreferences() != null) {
            dna.setLearningPreferences(
                    parseLearningStyle(response.learningPreferences().learningStyle())
            );
        }

        if (response.explanationPreferences() != null) {
            dna.setExplanationPreferences(
                    parseExplanationStyle(response.explanationPreferences().explanationStyle())
            );
        }

        dna.setConfidenceAreas(defaultList(response.confidenceAreas()));
        dna.setDifficultyAreas(defaultList(response.difficultyAreas()));
        dna.setRepeatedMistakes(defaultList(response.repeatedMistakes()));
        dna.setTopicAccuracy(defaultMap(response.topicAccuracy()));
        dna.setDifficultyProgression(defaultMap(response.difficultyProgression()));

        byteDNARepository.save(dna);

        return response;
    }

    public DiagnosisAiResponse diagnose(DiagnosisAiRequest request) {
        return aiClient.diagnose(request);
    }

    public DiagnosisSummaryAiResponse diagnoseSummary(
            DiagnosisSummaryAiRequest request) {

        return aiClient.diagnoseSummary(request);
    }

    @Transactional
    public ByteDnaEvolutionResponse evolveByteDna(
            ByteDnaEvolutionRequest request) {

        ByteDnaEvolutionResponse response =
                aiClient.evolveByteDna(request);

        ByteDNA dna = byteDNARepository.findByUser_Id(request.userId())
                .orElseThrow(() ->
                        new IllegalArgumentException(
                                "Byte DNA profile not found for user: "
                                        + request.userId()));

        ByteDnaEvolutionResponse.ByteDna updated =
                response.byteDNA();

        if (updated != null) {
            dna.setTechnicalExperience(
                    parseTechnicalExperience(updated.technicalExperience())
            );
            dna.setRepeatedMistakes(
                    defaultList(updated.repeatedMistakes())
            );
            dna.setTopicAccuracy(
                    defaultMap(updated.topicAccuracy())
            );
            dna.setConfidenceAreas(
                    defaultList(updated.confidenceAreas())
            );
            dna.setDifficultyAreas(
                    defaultList(updated.difficultyAreas())
            );
            dna.setDifficultyProgression(
                    defaultMap(updated.difficultyProgression())
            );

            byteDNARepository.save(dna);
        }

        return response;
    }

    @Transactional
    public RecommendationAiResponse recommend(
            RecommendationAiRequest request) {

        RecommendationAiResponse response =
                aiClient.recommend(request);

        String topic = response.topic();

        if (topic == null || topic.isBlank()) {
            throw new IllegalArgumentException(
                    "AI recommendation did not provide a topic");
        }

        Concept concept = curriculumResolver.resolveConcept(topic);

        RecommendationType type =
                mapRecommendationType(response.recommendedChallengeType());

        RecommendationPriority priority =
                mapPriority(response.basis());

        String title = response.recommendedChallengeType();

        if (title == null || title.isBlank()) {
            title = "Recommended practice";
        }

        CreateRecommendationRequest createRequest =
                new CreateRecommendationRequest(
                        request.userId(),
                        concept.getId(),
                        type,
                        RecommendationSource.AI_SUGGESTION,
                        priority,
                        title,
                        response.reason(),
                        buildRecommendationReason(response),
                        null
                );

        recommendationService.create(createRequest);

        return response;
    }

    private String buildRecommendationReason(
            RecommendationAiResponse response) {

        StringBuilder reason = new StringBuilder();

        if (response.basis() != null && !response.basis().isBlank()) {
            reason.append("AI basis: ")
                    .append(response.basis());
        }

        if (response.targetErrorCategory() != null
                && !response.targetErrorCategory().isBlank()) {

            if (!reason.isEmpty()) {
                reason.append(". ");
            }

            reason.append("Target error category: ")
                    .append(response.targetErrorCategory());
        }

        return reason.toString();
    }

    private RecommendationType mapRecommendationType(
            String challengeType) {

        if (challengeType == null) {
            return RecommendationType.REVISE_CONCEPT;
        }

        String value = challengeType.toLowerCase();

        if (value.contains("coding")
                || value.contains("implementation")) {
            return RecommendationType.PRACTICE_CODING;
        }

        if (value.contains("battle")
                || value.contains("scenario")
                || value.contains("tracing")) {
            return RecommendationType.RETRY_BATTLE;
        }

        if (value.contains("interview")) {
            return RecommendationType.TAKE_INTERVIEW;
        }

        if (value.contains("difficulty")) {
            return RecommendationType.ADJUST_DIFFICULTY;
        }

        return RecommendationType.REVISE_CONCEPT;
    }

    private RecommendationPriority mapPriority(String basis) {

        if (basis == null) {
            return RecommendationPriority.LOW;
        }

        return switch (basis.toLowerCase()) {
            case "repeated_error" -> RecommendationPriority.HIGH;
            case "weakest_dimension" -> RecommendationPriority.MEDIUM;
            case "insufficient_data" -> RecommendationPriority.LOW;
            default -> RecommendationPriority.MEDIUM;
        };
    }

    private ByteDNA.TechnicalExperience parseTechnicalExperience(
            String value) {

        if (value == null || value.isBlank()) {
            return ByteDNA.TechnicalExperience.BEGINNER;
        }

        return ByteDNA.TechnicalExperience.valueOf(
                value.trim().toUpperCase()
        );
    }

    private ByteDNA.LearningStyle parseLearningStyle(
            String value) {

        if (value == null || value.isBlank()) {
            return null;
        }

        String normalized = value.trim()
                .toUpperCase()
                .replace('-', '_')
                .replace(' ', '_');

        if ("INTERVIEW_PREP".equals(normalized)) {
            normalized = "INTERVEIW_PREP";
        }

        return ByteDNA.LearningStyle.valueOf(normalized);
    }

    private ByteDNA.ExplanationStyle parseExplanationStyle(
            String value) {

        if (value == null || value.isBlank()) {
            return null;
        }

        return ByteDNA.ExplanationStyle.valueOf(
                value.trim()
                        .toUpperCase()
                        .replace('-', '_')
                        .replace(' ', '_')
        );
    }

    private List<String> defaultList(List<String> value) {
        return value == null
                ? new ArrayList<>()
                : new ArrayList<>(value);
    }

    private Map<String, Object> defaultMap(
            Map<String, Object> value) {

        return value == null
                ? new HashMap<>()
                : new HashMap<>(value);
    }
}
