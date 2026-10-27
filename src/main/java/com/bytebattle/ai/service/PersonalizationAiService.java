package com.bytebattle.ai.service;

import com.bytebattle.ai.client.PersonalizationAiClient;
import com.bytebattle.ai.dto.personalization.*;
import com.bytebattle.bytedna.ByteDNA;
import com.bytebattle.bytedna.ByteDNARepository;
import com.bytebattle.coding.dto.ExecutionResult;
import com.bytebattle.curriculum.Concept;
import com.bytebattle.curriculum.ConceptRepository;
import com.bytebattle.recommendation.dto.CreateRecommendationRequest;
import com.bytebattle.recommendation.enums.RecommendationPriority;
import com.bytebattle.recommendation.enums.RecommendationSource;
import com.bytebattle.recommendation.enums.RecommendationType;
import com.bytebattle.recommendation.repository.RecommendationRepository;
import com.bytebattle.recommendation.service.RecommendationService;
import com.bytebattle.user.User;
import com.bytebattle.user.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class PersonalizationAiService {

    private static final Logger log = LoggerFactory.getLogger(PersonalizationAiService.class);

    /** Recommendations for the same user + type + concept are not re-created within this window. */
    static final Duration RECOMMENDATION_DEDUPE_WINDOW = Duration.ofHours(24);

    private final PersonalizationAiClient aiClient;
    private final ByteDNARepository byteDNARepository;
    private final ConceptRepository conceptRepository;
    private final UserRepository userRepository;
    private final AiCurriculumResolver curriculumResolver;
    private final RecommendationService recommendationService;
    private final RecommendationRepository recommendationRepository;

    public PersonalizationAiService(
            PersonalizationAiClient aiClient,
            ByteDNARepository byteDNARepository,
            ConceptRepository conceptRepository,
            UserRepository userRepository,
            AiCurriculumResolver curriculumResolver,
            RecommendationService recommendationService,
            RecommendationRepository recommendationRepository) {

        this.aiClient = aiClient;
        this.byteDNARepository = byteDNARepository;
        this.conceptRepository = conceptRepository;
        this.userRepository = userRepository;
        this.curriculumResolver = curriculumResolver;
        this.recommendationService = recommendationService;
        this.recommendationRepository = recommendationRepository;
    }

    @Transactional
    public ByteDnaAiResponse onboard(OnboardingAiRequest request) {

        return saveOnboarding(request.userId(), aiClient.onboard(request));
    }

    /** Persists an onboarding result as the user's Byte DNA (create or overwrite). Joins a surrounding transaction. */
    @Transactional
    public ByteDnaAiResponse saveOnboarding(java.util.UUID userId, ByteDnaAiResponse response) {

        User user = userRepository.findById(userId)
                .orElseThrow(() ->
                        new IllegalArgumentException("User not found: " + userId));

        ByteDNA dna = byteDNARepository.findByUser_Id(userId)
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

    /**
     * Processes one completed coding attempt through the personalization pipeline.
     *
     * The coding execution result is the source of truth for this event.
     * Historical performance averages are intentionally not used here because
     * Byte DNA evolution expects the accuracy of the new attempt.
     */
    public void processCodingAttempt(
            java.util.UUID userId,
            java.util.UUID conceptId,
            ExecutionResult result) {

        try {
            doProcessCodingAttempt(userId, conceptId, result);
        } catch (RuntimeException e) {
            // Best effort: personalization must never invalidate a valid coding submission.
            log.error("Coding personalization failed for user={} concept={}", userId, conceptId, e);
        }
    }

    private void doProcessCodingAttempt(
            java.util.UUID userId,
            java.util.UUID conceptId,
            ExecutionResult result) {

        int total = result.testCasesTotal();
        int passed = result.testCasesPassed();
        double accuracy = total > 0 ? (double) passed / total : 0.0;

        runPipeline(new ActivityEvidence(
                userId, conceptId, "coding", accuracy, (int) Math.round(accuracy * 100.0),
                1, 0, 0, passed, total,
                result.status() == com.bytebattle.coding.enums.CodingSubmissionStatus.PASSED));
    }

    /** Evidence of one finished activity (battle, debugging, interview, coding) for the personalization pipeline. */
    public record ActivityEvidence(
            java.util.UUID userId,
            java.util.UUID conceptId,
            String activityType,          // battle | coding | debugging | interview (the AI service's vocabulary)
            double accuracy,
            int score,
            int attemptCount,
            int timeSpentSeconds,
            int hintsUsed,
            Integer testCasesPassed,
            Integer testCasesTotal,
            boolean success) {
    }

    /**
     * Same pipeline as coding, for any activity: diagnose, evolve Byte DNA, recommend. Best effort:
     * personalization must never invalidate a result that was already graded and stored.
     */
    public void processActivity(ActivityEvidence evidence) {
        try {
            runPipeline(evidence);
        } catch (RuntimeException e) {
            log.error("Personalization failed for user={} concept={} activity={}",
                    evidence.userId(), evidence.conceptId(), evidence.activityType(), e);
        }
    }

    private void runPipeline(ActivityEvidence e) {
        java.util.UUID userId = e.userId();

        Concept concept = conceptRepository.findById(e.conceptId())
                .orElseThrow(() ->
                        new IllegalArgumentException(
                                "Concept not found: " + e.conceptId()));

        if (concept.getTopic() == null
                || concept.getTopic().getSlug() == null
                || concept.getTopic().getSlug().isBlank()) {
            throw new IllegalArgumentException(
                    "Concept has no valid curriculum topic: " + e.conceptId());
        }

        String topic = concept.getTopic().getSlug();

        ByteDNA dna = byteDNARepository.findByUser_Id(userId).orElse(null);
        if (dna == null) {
            log.warn("Skipping personalization: user {} has no Byte DNA (onboarding not completed)", userId);
            return;
        }

        DiagnosisAiResponse diagnosis = diagnose(new DiagnosisAiRequest(
                userId,
                e.activityType(),
                e.accuracy(),
                e.score(),
                e.attemptCount(),
                e.timeSpentSeconds(),
                e.hintsUsed(),
                e.testCasesPassed(),
                e.testCasesTotal(),
                e.success()));

        ByteDnaEvolutionResponse evolution = evolveByteDna(new ByteDnaEvolutionRequest(
                userId,
                topic,
                buildEvolutionByteDna(dna),
                new ByteDnaEvolutionRequest.Diagnosis(null),
                new ByteDnaEvolutionRequest.Performance(e.accuracy())));

        ByteDnaEvolutionResponse.ByteDna evolvedDna = evolution.byteDNA();

        if (evolvedDna == null) {
            throw new IllegalStateException(
                    "AI Byte DNA evolution returned no Byte DNA");
        }

        recommend(new RecommendationAiRequest(
                userId,
                evolvedDna.technicalExperience(),
                topic,
                defaultList(evolvedDna.repeatedMistakes()),
                diagnosis.conceptUnderstanding(),
                diagnosis.decisionMaking(),
                diagnosis.boundaryConditions(),
                diagnosis.codingImplementation(),
                diagnosis.hintDependency()));
    }

    private ByteDnaEvolutionRequest.ByteDna buildEvolutionByteDna(
            ByteDNA dna) {

        String technicalExperience =
                dna.getTechnicalExperience() == null
                        ? "BEGINNER"
                        : dna.getTechnicalExperience().name();

        return new ByteDnaEvolutionRequest.ByteDna(
                technicalExperience,
                defaultList(dna.getRepeatedMistakes()),
                defaultMap(dna.getTopicAccuracy()),
                defaultList(dna.getConfidenceAreas()),
                defaultList(dna.getDifficultyAreas()),
                defaultMap(dna.getDifficultyProgression())
        );
    }

    /**
     * Evolves ONLY the caller's own Byte DNA. The userId and the Byte DNA snapshot in the request are
     * ignored and replaced by the caller's id and the stored DNA; only the diagnosis/topic/performance
     * of the event come from the client.
     */
    public ByteDnaEvolutionResponse evolveByteDnaForUser(java.util.UUID userId, ByteDnaEvolutionRequest request) {
        ByteDNA dna = byteDNARepository.findByUser_Id(userId)
                .orElseThrow(() -> new com.bytebattle.exception.ResourceNotFoundException(
                        "Byte DNA profile not found; complete onboarding first"));
        ByteDnaEvolutionRequest bound = new ByteDnaEvolutionRequest(
                userId, request.topic(), buildEvolutionByteDna(dna), request.diagnosis(), request.performance());
        return evolveByteDna(bound);
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

        boolean duplicate = recommendationRepository.existsByUserIdAndTypeAndConceptIdAndCreatedAtAfter(
                request.userId(), type, concept.getId(),
                Instant.now().minus(RECOMMENDATION_DEDUPE_WINDOW));

        if (duplicate) {
            log.debug("Skipping duplicate recommendation user={} type={} concept={}",
                    request.userId(), type, concept.getId());
        } else {
            recommendationService.create(createRequest);
        }

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

    private ByteDNA.TechnicalExperience parseTechnicalExperience(String value) {
        return parseEnum(ByteDNA.TechnicalExperience.class, value, ByteDNA.TechnicalExperience.BEGINNER);
    }

    private ByteDNA.LearningStyle parseLearningStyle(String value) {
        // "INTERVEIW_PREP" was the legacy (typo) spelling of the constant
        String v = value == null ? null : value.trim().toUpperCase().replace("INTERVEIW", "INTERVIEW");
        return parseEnum(ByteDNA.LearningStyle.class, v, null);
    }

    private ByteDNA.ExplanationStyle parseExplanationStyle(String value) {
        return parseEnum(ByteDNA.ExplanationStyle.class, value, null);
    }

    /** Never throws: unknown/blank AI strings fall back to the default (with a warning). */
    static <E extends Enum<E>> E parseEnum(Class<E> type, String value, E defaultValue) {
        if (value == null || value.isBlank()) {
            return defaultValue;
        }
        String normalized = value.trim().toUpperCase().replace('-', '_').replace(' ', '_');
        try {
            return Enum.valueOf(type, normalized);
        } catch (IllegalArgumentException e) {
            log.warn("Unknown {} value from AI: '{}'; using default {}", type.getSimpleName(), value, defaultValue);
            return defaultValue;
        }
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
