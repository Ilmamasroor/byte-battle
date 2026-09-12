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
import org.springframework.security.core.context.SecurityContextHolder;
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

    private final AiFeatureClient aiFeatureClient;
    private final ConceptRepository conceptRepository;
    private final ByteDNARepository byteDNARepository;

    public AiFeatureService(
            AiFeatureClient aiFeatureClient,
            ConceptRepository conceptRepository,
            ByteDNARepository byteDNARepository) {

        this.aiFeatureClient = aiFeatureClient;
        this.conceptRepository = conceptRepository;
        this.byteDNARepository = byteDNARepository;
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

        Map<String, Object> canonicalKnowledge = new LinkedHashMap<>();

        CanonicalKnowledgeResponse knowledge =
                generateCanonicalKnowledge(conceptId);

        canonicalKnowledge.put("keyPoints", knowledge.keyPoints());
        canonicalKnowledge.put("rules", knowledge.rules());
        canonicalKnowledge.put("examples", knowledge.examples());

        Map<String, Object> byteDNAData = buildByteDNAData();

        AnalogyRequest request = new AnalogyRequest(
                conceptData,
                canonicalKnowledge,
                byteDNAData
        );

        return aiFeatureClient.generateAnalogy(request);
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

        return ((com.bytebattle.security.CustomUserDetails)
                SecurityContextHolder
                        .getContext()
                        .getAuthentication()
                        .getPrincipal())
                .getUser()
                .getId();
    }
public MnemonicResponse generateMnemonic(UUID conceptId) {

    Concept concept = conceptRepository.findById(conceptId)
            .orElseThrow(() ->
                    new IllegalArgumentException(
                            "Concept not found: " + conceptId));

    Map<String, Object> conceptData = buildConceptData(concept);

    CanonicalKnowledgeResponse knowledge =
            generateCanonicalKnowledge(conceptId);

    Map<String, Object> canonicalKnowledge = new LinkedHashMap<>();
    canonicalKnowledge.put("keyPoints", knowledge.keyPoints());
    canonicalKnowledge.put("rules", knowledge.rules());
    canonicalKnowledge.put("examples", knowledge.examples());

    Map<String, Object> byteDNAData = buildByteDNAData();

    MnemonicRequest request = new MnemonicRequest(
            conceptData,
            canonicalKnowledge,
            byteDNAData
    );

    return aiFeatureClient.generateMnemonic(request);
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

    return aiFeatureClient.generateBattleHint(request);
}

public CodingFeedbackResponse generateCodingFeedback(
        Map<String, Object> conceptData,
        Map<String, Object> diagnosis) {

    CodingFeedbackRequest request = new CodingFeedbackRequest(
            conceptData,
            diagnosis
    );

    return aiFeatureClient.generateCodingFeedback(request);
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

    return aiFeatureClient.generateDebuggingHint(request);
}
public BossBattleResponse generateBossBattle(
        Map<String, Object> conceptData,
        Map<String, Object> canonicalKnowledge) {

    BossBattleRequest request = new BossBattleRequest(
            conceptData,
            canonicalKnowledge
    );

    return aiFeatureClient.generateBossBattle(request);
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

    return aiFeatureClient.generateAiInterviewQuestion(request);
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

}
