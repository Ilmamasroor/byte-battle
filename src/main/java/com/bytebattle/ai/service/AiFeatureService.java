package com.bytebattle.ai.service;

import com.bytebattle.ai.client.AiFeatureClient;
import com.bytebattle.ai.dto.feature.AnalogyRequest;
import com.bytebattle.ai.dto.feature.AnalogyResponse;
import com.bytebattle.ai.dto.feature.CanonicalKnowledgeRequest;
import com.bytebattle.ai.dto.feature.CanonicalKnowledgeResponse;
import com.bytebattle.bytedna.ByteDNA;
import com.bytebattle.bytedna.ByteDNARepository;
import com.bytebattle.curriculum.Concept;
import com.bytebattle.curriculum.ConceptRepository;
import com.bytebattle.ai.exception.AiServiceException;
import com.bytebattle.security.CurrentUser;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import com.bytebattle.ai.dto.feature.MnemonicRequest;
import com.bytebattle.ai.dto.feature.MnemonicResponse;
import com.bytebattle.ai.dto.feature.BattleHintRequest;
import com.bytebattle.ai.dto.feature.BattleHintResponse;
import com.bytebattle.ai.dto.feature.CodingFeedbackRequest;
import com.bytebattle.ai.dto.feature.CodingFeedbackResponse;
import com.bytebattle.ai.dto.feature.DebuggingHintRequest;
import com.bytebattle.ai.dto.feature.DebuggingHintResponse;
import com.bytebattle.ai.dto.feature.BossBattleRequest;
import com.bytebattle.ai.dto.feature.BossBattleResponse;
import com.bytebattle.ai.dto.feature.AiInterviewQuestionRequest;
import com.bytebattle.ai.dto.feature.AiInterviewQuestionResponse;
import com.bytebattle.ai.dto.feature.AiInterviewEvaluateRequest;
import com.bytebattle.ai.dto.feature.AiInterviewEvaluateResponse;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;

@Service
public class AiFeatureService {

    private static final Logger log = LoggerFactory.getLogger(AiFeatureService.class);

    private final AiFeatureClient aiFeatureClient;
    private final ConceptRepository conceptRepository;
    private final ByteDNARepository byteDNARepository;
    private final CurrentUser currentUser;

    public AiFeatureService(
            AiFeatureClient aiFeatureClient,
            ConceptRepository conceptRepository,
            ByteDNARepository byteDNARepository,
            CurrentUser currentUser) {

        this.aiFeatureClient = aiFeatureClient;
        this.conceptRepository = conceptRepository;
        this.byteDNARepository = byteDNARepository;
        this.currentUser = currentUser;
    }

    public CanonicalKnowledgeResponse generateCanonicalKnowledge(UUID conceptId) {

        Concept concept = conceptRepository.findById(conceptId)
                .orElseThrow(() ->
                        new IllegalArgumentException(
                                "Concept not found: " + conceptId));

        Map<String, Object> conceptData = buildConceptData(concept);

        CanonicalKnowledgeRequest request =
                new CanonicalKnowledgeRequest(conceptData);

        return aiFeatureClient.generateCanonicalKnowledge(request);
    }

    public AnalogyResponse generateAnalogy(UUID conceptId) {

        Concept concept = conceptRepository.findById(conceptId)
                .orElseThrow(() ->
                        new IllegalArgumentException(
                                "Concept not found: " + conceptId));

        Map<String, Object> conceptData = buildConceptData(concept);
        Map<String, Object> byteDNAData = buildByteDNAData();

        try {
            Map<String, Object> canonicalKnowledge = new LinkedHashMap<>();

            CanonicalKnowledgeResponse knowledge =
                    generateCanonicalKnowledge(conceptId);

            canonicalKnowledge.put("keyPoints", knowledge.keyPoints());
            canonicalKnowledge.put("rules", knowledge.rules());
            canonicalKnowledge.put("examples", knowledge.examples());

            AnalogyRequest request = new AnalogyRequest(
                    conceptData,
                    canonicalKnowledge,
                    byteDNAData
            );

            return aiFeatureClient.generateAnalogy(request);
        } catch (AiServiceException e) {
            logFallback("analogy", e);
            String name = conceptName(conceptData);
            return new AnalogyResponse(
                    conceptData,
                    "Think of " + name + " like a familiar everyday routine: break it into small, ordered steps you already understand.",
                    "Map each step of the routine to a step of " + name + " and check where the comparison holds.",
                    "Say " + name + " out loud in your own words once, then write one tiny example.",
                    Boolean.TRUE);
        }
    }

    private Map<String, Object> buildConceptData(Concept concept) {

        Map<String, Object> conceptData = new LinkedHashMap<>();

        conceptData.put("id", concept.getId().toString());
        conceptData.put("name", concept.getName());
        conceptData.put("description", concept.getDescription());
        conceptData.put("slug", concept.getSlug());

        conceptData.put(
                "difficulty",
                concept.getDifficulty() != null
                        ? concept.getDifficulty().name()
                        : null
        );

        conceptData.put("displayOrder", concept.getDisplayOrder());
        if (concept.getTopic() != null) {
            conceptData.put("topic", concept.getTopic().getName());
        }

        return conceptData;
    }

    private Map<String, Object> buildByteDNAData() {

        UUID userId = getCurrentUserId();

        ByteDNA dna = byteDNARepository.findByUser_Id(userId)
                .orElseThrow(() ->
                        new IllegalArgumentException(
                                "Byte DNA profile not found for this user"));

        Map<String, Object> data = new LinkedHashMap<>();

        data.put(
                "technicalExperience",
                dna.getTechnicalExperience() != null
                        ? dna.getTechnicalExperience().name()
                        : null
        );

        data.put("careerGoal", dna.getCareerGoal());
        data.put("interests", dna.getInterests());
        data.put("preferredLanguage", dna.getPreferredLanguage());

        data.put(
                "learningPreferences",
                dna.getLearningPreferences() != null
                        ? dna.getLearningPreferences().name()
                        : null
        );

        data.put("confidenceAreas", dna.getConfidenceAreas());
        data.put("difficultyAreas", dna.getDifficultyAreas());

        data.put(
                "explanationPreferences",
                dna.getExplanationPreferences() != null
                        ? dna.getExplanationPreferences().name()
                        : null
        );

        data.put("repeatedMistakes", dna.getRepeatedMistakes());
        data.put("topicAccuracy", dna.getTopicAccuracy());
        data.put("difficultyProgression", dna.getDifficultyProgression());

        return data;
    }

    private UUID getCurrentUserId() {
        return currentUser.id();
    }

public MnemonicResponse generateMnemonic(UUID conceptId) {

    Concept concept = conceptRepository.findById(conceptId)
            .orElseThrow(() ->
                    new IllegalArgumentException(
                            "Concept not found: " + conceptId));

    Map<String, Object> conceptData = buildConceptData(concept);
    Map<String, Object> byteDNAData = buildByteDNAData();

    try {
        CanonicalKnowledgeResponse knowledge =
                generateCanonicalKnowledge(conceptId);

        Map<String, Object> canonicalKnowledge = new LinkedHashMap<>();
        canonicalKnowledge.put("keyPoints", knowledge.keyPoints());
        canonicalKnowledge.put("rules", knowledge.rules());
        canonicalKnowledge.put("examples", knowledge.examples());

        MnemonicRequest request = new MnemonicRequest(
                conceptData,
                canonicalKnowledge,
                byteDNAData
        );

        return aiFeatureClient.generateMnemonic(request);
    } catch (AiServiceException e) {
        logFallback("mnemonic", e);
        String name = conceptName(conceptData);
        String letters = initials(name);
        return new MnemonicResponse(
                conceptData,
                new MnemonicResponse.MnemonicData(
                        "Remember " + name + " with the letters " + letters + ": invent one short phrase using each letter.",
                        "Review " + name + " again tomorrow, then in three days."),
                Boolean.TRUE);
    }
}

public BattleHintResponse generateBattleHint(
        Map<String, Object> conceptData,
        String question,
        Map<String, Object> canonicalKnowledge,
        Integer hintLevel) {

    BattleHintRequest request = new BattleHintRequest(
            conceptData,
            question,
            canonicalKnowledge,
            hintLevel
    );

    try {
        return aiFeatureClient.generateBattleHint(request);
    } catch (AiServiceException e) {
        logFallback("battle-hint", e);
        String name = conceptName(conceptData);
        return new BattleHintResponse(
                conceptData,
                question,
                new BattleHintResponse.HintData(
                        hintLevel,
                        "Re-read the question and think about the core rule of " + name + " before choosing.",
                        "Eliminate the options that clearly contradict " + name + "."),
                Boolean.TRUE);
    }
}

public CodingFeedbackResponse generateCodingFeedback(
        Map<String, Object> conceptData,
        Map<String, Object> diagnosis) {

    CodingFeedbackRequest request = new CodingFeedbackRequest(
            conceptData,
            diagnosis
    );

    try {
        return aiFeatureClient.generateCodingFeedback(request);
    } catch (AiServiceException e) {
        logFallback("coding-feedback", e);
        return new CodingFeedbackResponse(
                "Automated feedback is unavailable right now. Re-check the failing test cases against the core rule of "
                        + conceptName(conceptData) + ", then trace your code by hand on the smallest input.",
                Boolean.TRUE);
    }
}
public DebuggingHintResponse generateDebuggingHint(
        Map<String, Object> conceptData,
        Map<String, Object> diagnosis,
        Integer hintLevel) {

    DebuggingHintRequest request = new DebuggingHintRequest(
            conceptData,
            diagnosis,
            hintLevel
    );

    try {
        return aiFeatureClient.generateDebuggingHint(request);
    } catch (AiServiceException e) {
        logFallback("debugging-hint", e);
        return new DebuggingHintResponse(
                "Reproduce the failure on the smallest input, print the values at each step, and compare them with what "
                        + conceptName(conceptData) + " says they should be.",
                Boolean.TRUE);
    }
}
public BossBattleResponse generateBossBattle(
        Map<String, Object> conceptData,
        Map<String, Object> canonicalKnowledge) {

    BossBattleRequest request = new BossBattleRequest(
            conceptData,
            canonicalKnowledge
    );

    try {
        return aiFeatureClient.generateBossBattle(request);
    } catch (AiServiceException e) {
        logFallback("boss-battle", e);
        String name = conceptName(conceptData);
        return new BossBattleResponse(
                "Boss challenge: a system relies on " + name + " under tricky edge cases. "
                        + "Decide which approach is correct and justify it.",
                java.util.List.of(
                        "Apply the core rule of " + name + " directly",
                        "Handle the edge case first, then apply " + name,
                        "Skip " + name + " and use a workaround",
                        "None of the above"),
                Boolean.TRUE);
    }
}
public AiInterviewQuestionResponse generateAiInterviewQuestion(
        Map<String, Object> conceptData,
        Map<String, Object> canonicalKnowledge,
        java.util.List<Object> conversationHistory) {

    AiInterviewQuestionRequest request =
            new AiInterviewQuestionRequest(
                    conceptData,
                    canonicalKnowledge,
                    conversationHistory
            );

    try {
        return aiFeatureClient.generateAiInterviewQuestion(request);
    } catch (AiServiceException e) {
        logFallback("interview-question", e);
        return new AiInterviewQuestionResponse(
                "Explain " + conceptName(conceptData) + " in your own words and give one example of when you would use it.",
                Boolean.TRUE);
    }
}

public AiInterviewEvaluateResponse evaluateInterviewAnswer(
        Map<String, Object> conceptData,
        Map<String, Object> canonicalKnowledge,
        String question,
        String learnerAnswer) {

    AiInterviewEvaluateRequest request =
            new AiInterviewEvaluateRequest(
                    conceptData,
                    canonicalKnowledge,
                    question,
                    learnerAnswer
            );

    return aiFeatureClient.evaluateInterviewAnswer(request);
}


    /**
     * Interview question for a stored concept. Canonical knowledge is intentionally not sent: the AI service
     * then grounds the question in its curated content index. Falls back to a template when AI is down.
     */
    public AiInterviewQuestionResponse generateInterviewQuestionForConcept(
            UUID conceptId, java.util.List<Object> conversationHistory) {
        Concept concept = conceptRepository.findById(conceptId)
                .orElseThrow(() -> new IllegalArgumentException("Concept not found: " + conceptId));
        return generateAiInterviewQuestion(buildConceptData(concept), Map.of(), conversationHistory);
    }

    /** Rubric evaluation of one interview answer; {@code null} when the AI service is unavailable. */
    public AiInterviewEvaluateResponse evaluateInterviewAnswerForConcept(
            UUID conceptId, String question, String learnerAnswer) {
        Concept concept = conceptRepository.findById(conceptId)
                .orElseThrow(() -> new IllegalArgumentException("Concept not found: " + conceptId));
        try {
            return evaluateInterviewAnswer(buildConceptData(concept), Map.of(), question, learnerAnswer);
        } catch (AiServiceException e) {
            logFallback("interview-evaluate", e);
            return null;
        }
    }

    private void logFallback(String feature, AiServiceException e) {
        log.warn("AI feature '{}' unavailable (code={}), serving template fallback", feature, e.getCode());
    }

    /** Concept name from either the curriculum shape ("name") or the AiRequest shape ("conceptName"). */
    public static String conceptName(Map<String, Object> conceptData) {
        if (conceptData != null) {
            for (String key : new String[] {"name", "conceptName", "topic"}) {
                Object v = conceptData.get(key);
                if (v instanceof String str && !str.isBlank()) {
                    return str;
                }
            }
        }
        return "this concept";
    }

    private static String initials(String name) {
        StringBuilder sb = new StringBuilder();
        for (String word : name.trim().split("\\s+")) {
            if (!word.isEmpty()) {
                sb.append(Character.toUpperCase(word.charAt(0)));
            }
        }
        return sb.length() == 0 ? "?" : sb.toString();
    }

}
