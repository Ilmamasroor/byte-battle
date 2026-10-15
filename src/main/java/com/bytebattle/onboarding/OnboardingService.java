package com.bytebattle.onboarding;

import com.bytebattle.ai.client.PersonalizationAiClient;
import com.bytebattle.ai.dto.personalization.ByteDnaAiResponse;
import com.bytebattle.ai.dto.personalization.OnboardingAiRequest;
import com.bytebattle.ai.exception.AiServiceException;
import com.bytebattle.exception.BadRequestException;
import com.bytebattle.onboarding.OnboardingResponses.Result;
import com.bytebattle.onboarding.OnboardingResponses.Status;
import com.bytebattle.security.OnboardingStatusProvider;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

/**
 * Turns the onboarding answers into the baseline Byte DNA (cold start) plus the learner profile.
 * The AI service builds the baseline; if it is unreachable the same mapping is built locally,
 * so a learner can never be blocked from starting by an AI outage.
 */
@Service
public class OnboardingService {

    private static final Logger log = LoggerFactory.getLogger(OnboardingService.class);

    private final PersonalizationAiClient aiClient;
    private final OnboardingStore store;
    private final OnboardingQuestionnaire questionnaire;
    private final OnboardingStatusProvider statusProvider;
    private final com.bytebattle.learner.LearnerProfileRepository learnerProfileRepository;
    private final com.bytebattle.bytedna.ByteDNARepository byteDNARepository;

    public OnboardingService(PersonalizationAiClient aiClient,
                             OnboardingStore store,
                             OnboardingQuestionnaire questionnaire,
                             OnboardingStatusProvider statusProvider,
                             com.bytebattle.learner.LearnerProfileRepository learnerProfileRepository,
                             com.bytebattle.bytedna.ByteDNARepository byteDNARepository) {
        this.aiClient = aiClient;
        this.store = store;
        this.questionnaire = questionnaire;
        this.statusProvider = statusProvider;
        this.learnerProfileRepository = learnerProfileRepository;
        this.byteDNARepository = byteDNARepository;
    }

    public List<OnboardingQuestion> questions() {
        return questionnaire.questions();
    }

    public Status status(UUID userId) {
        return new Status(statusProvider.isOnboardingCompleted(userId),
                learnerProfileRepository.existsByUser_Id(userId),
                byteDNARepository.existsByUser_Id(userId));
    }

    /** Idempotent: submitting again (retaking the questionnaire) overwrites the baseline. */
    public Result complete(UUID userId, OnboardingRequest request) {
        List<String> interests = clean(request.interests(), true);
        List<String> confident = clean(request.confidenceAreas(), false);
        List<String> difficult = clean(request.difficultyAreas(), false);
        validateAreas(confident, difficult);

        OnboardingAiRequest aiRequest = new OnboardingAiRequest(
                userId,
                request.technicalExperience().name(),
                request.preferredLanguage().trim().toUpperCase(Locale.ROOT),
                request.careerGoal().trim(),
                request.learningStyle().name(),
                request.explanationStyle().name(),
                interests);

        ByteDnaAiResponse baseline;
        try {
            baseline = aiClient.onboard(aiRequest);
        } catch (AiServiceException e) {
            log.warn("AI onboarding unavailable (code={}); building the baseline Byte DNA locally", e.getCode());
            baseline = localBaseline(aiRequest);
        }
        // the learner's own self-assessment is authoritative for the starting point
        ByteDnaAiResponse withSelfAssessment = new ByteDnaAiResponse(
                userId, baseline.technicalExperience(), baseline.careerGoal(), baseline.interests(),
                baseline.preferredLanguage(), baseline.learningPreferences(), baseline.explanationPreferences(),
                confident, difficult, List.of(), Map.of(), Map.of());

        store.persist(userId, request, withSelfAssessment);

        return new Result(true, request.technicalExperience().name(), aiRequest.preferredLanguage(),
                aiRequest.careerGoal(), request.learningStyle().name(), request.explanationStyle().name(),
                interests, request.dailyGoalMinutes(), confident, difficult);
    }

    static ByteDnaAiResponse localBaseline(OnboardingAiRequest r) {
        return new ByteDnaAiResponse(
                r.userId(), r.technicalExperience(), r.careerGoal(), r.interests(), r.preferredLanguage(),
                new ByteDnaAiResponse.LearningPreferences(r.learningStyle()),
                new ByteDnaAiResponse.ExplanationPreferences(r.explanationStyle()),
                List.of(), List.of(), List.of(), Map.of(), Map.of());
    }

    private void validateAreas(List<String> confident, List<String> difficult) {
        Set<String> known = questionnaire.topicSlugs();
        for (String slug : concat(confident, difficult)) {
            if (!known.contains(slug)) {
                throw new BadRequestException("Unknown topic: " + slug);
            }
        }
        Set<String> overlap = new HashSet<>(confident);
        overlap.retainAll(difficult);
        if (!overlap.isEmpty()) {
            throw new BadRequestException("A topic cannot be both confident and difficult: " + overlap);
        }
    }

    private static List<String> concat(List<String> a, List<String> b) {
        List<String> all = new ArrayList<>(a);
        all.addAll(b);
        return all;
    }

    /** Trims, drops blanks and duplicates (case-insensitively for free text), keeps order. */
    private static List<String> clean(List<String> values, boolean lowerCase) {
        List<String> out = new ArrayList<>();
        Set<String> seen = new HashSet<>();
        if (values != null) {
            for (String v : values) {
                String t = v == null ? "" : v.trim();
                String key = t.toLowerCase(Locale.ROOT);
                if (!t.isEmpty() && seen.add(key)) {
                    out.add(lowerCase ? key : t);
                }
            }
        }
        return out;
    }
}
