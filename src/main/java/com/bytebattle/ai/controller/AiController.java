package com.bytebattle.ai.controller;

import com.bytebattle.ai.dto.AiResponse;
import com.bytebattle.ai.dto.personalization.*;
import com.bytebattle.ai.service.ExplanationService;
import com.bytebattle.ai.service.PersonalizationAiService;
import org.springframework.web.bind.annotation.*;
import com.bytebattle.ai.dto.feature.CanonicalKnowledgeResponse;
import com.bytebattle.ai.service.AiFeatureService;
import java.util.UUID;
import com.bytebattle.ai.dto.feature.AnalogyResponse;
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

@RestController
@RequestMapping("/api/ai")
public class AiController {

    private final ExplanationService explanationService;
    private final PersonalizationAiService personalizationAiService;
    private final AiFeatureService aiFeatureService;

    public AiController(
            ExplanationService explanationService,
            PersonalizationAiService personalizationAiService,
            AiFeatureService aiFeatureService) {

        this.explanationService = explanationService;
        this.personalizationAiService = personalizationAiService;
        this.aiFeatureService = aiFeatureService;
    }

    @PostMapping("/explanation")
    public AiResponse explanation(
            @RequestParam java.util.UUID userId,
            @RequestParam java.util.UUID conceptId) {

        return explanationService.explain(userId, conceptId);
    }

    @PostMapping("/onboarding")
    public ByteDnaAiResponse onboarding(
            @RequestBody OnboardingAiRequest request) {

        return personalizationAiService.onboard(request);
    }

    @PostMapping("/diagnose")
    public DiagnosisAiResponse diagnose(
            @RequestBody DiagnosisAiRequest request) {

        return personalizationAiService.diagnose(request);
    }

    @PostMapping("/diagnose/summary")
    public DiagnosisSummaryAiResponse diagnoseSummary(
            @RequestBody DiagnosisSummaryAiRequest request) {

        return personalizationAiService.diagnoseSummary(request);
    }

    @PostMapping("/recommend")
    public RecommendationAiResponse recommend(
            @RequestBody RecommendationAiRequest request) {

        return personalizationAiService.recommend(request);
    }

    @PostMapping("/byte-dna/evolve")
    public ByteDnaEvolutionResponse evolveByteDna(
            @RequestBody ByteDnaEvolutionRequest request) {

        return personalizationAiService.evolveByteDna(request);
    }

@PostMapping("/canonical-knowledge")
public CanonicalKnowledgeResponse canonicalKnowledge(
        @RequestParam UUID conceptId) {

    return aiFeatureService.generateCanonicalKnowledge(conceptId);
}

@PostMapping("/analogy")
public AnalogyResponse analogy(
        @RequestParam java.util.UUID conceptId) {

    return aiFeatureService.generateAnalogy(conceptId);
}

@PostMapping("/mnemonic")
public MnemonicResponse mnemonic(
        @RequestParam java.util.UUID conceptId) {

    return aiFeatureService.generateMnemonic(conceptId);
}
@PostMapping("/battle-hint")
public BattleHintResponse generateBattleHint(
        @RequestBody BattleHintRequest request) {

    return aiFeatureService.generateBattleHint(
            request.concept(),
            request.question(),
            request.canonicalKnowledge(),
            request.hintLevel()
    );
}
@PostMapping("/coding-feedback")
public CodingFeedbackResponse generateCodingFeedback(
        @RequestBody CodingFeedbackRequest request) {

    return aiFeatureService.generateCodingFeedback(
            request.concept(),
            request.diagnosis()
    );
}
@PostMapping("/debugging-hint")
public DebuggingHintResponse generateDebuggingHint(
        @RequestBody DebuggingHintRequest request) {

    return aiFeatureService.generateDebuggingHint(
            request.concept(),
            request.diagnosis(),
            request.hintLevel()
    );
}
@PostMapping("/boss-battle")
public BossBattleResponse generateBossBattle(
        @RequestBody BossBattleRequest request) {

    return aiFeatureService.generateBossBattle(
            request.concept(),
            request.canonicalKnowledge()
    );
}
@PostMapping("/interview/question")
public AiInterviewQuestionResponse generateAiInterviewQuestion(
        @RequestBody AiInterviewQuestionRequest request) {

    return aiFeatureService.generateAiInterviewQuestion(
            request.concept(),
            request.canonicalKnowledge(),
            request.conversationHistory()
    );
}

@PostMapping("/interview/evaluate")
public AiInterviewEvaluateResponse evaluateInterviewAnswer(
        @RequestBody AiInterviewEvaluateRequest request) {

    return aiFeatureService.evaluateInterviewAnswer(
            request.concept(),
            request.canonicalKnowledge(),
            request.question(),
            request.learnerAnswer()
    );
}

}
