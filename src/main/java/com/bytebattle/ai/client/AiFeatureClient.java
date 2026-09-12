package com.bytebattle.ai.client;

import com.bytebattle.ai.dto.feature.*;
import com.bytebattle.ai.exception.AiServiceException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

@Component
public class AiFeatureClient {

    private final RestClient restClient;

    public AiFeatureClient(
            @Value("${bytebattle.ai.personalization.base-url:http://localhost:8000}")
            String baseUrl) {

        this.restClient = RestClient.builder()
                .baseUrl(baseUrl)
                .build();
    }

    public AnalogyResponse generateAnalogy(AnalogyRequest request) {
        return post("/ai/analogy", request, AnalogyResponse.class);
    }

    public BattleHintResponse generateBattleHint(BattleHintRequest request) {
        return post("/ai/battle-hint", request, BattleHintResponse.class);
    }

    public CanonicalKnowledgeResponse generateCanonicalKnowledge(
            CanonicalKnowledgeRequest request) {

        return post(
                "/ai/canonical-knowledge",
                request,
                CanonicalKnowledgeResponse.class
        );
    }

    public MnemonicResponse generateMnemonic(MnemonicRequest request) {
        return post("/ai/mnemonic", request, MnemonicResponse.class);
    }

    public CodingFeedbackResponse generateCodingFeedback(
            CodingFeedbackRequest request) {

        return post(
                "/coding/feedback",
                request,
                CodingFeedbackResponse.class
        );
    }

    public DebuggingHintResponse generateDebuggingHint(
            DebuggingHintRequest request) {

        return post(
                "/debugging/hint",
                request,
                DebuggingHintResponse.class
        );
    }

    public BossBattleResponse generateBossBattle(
            BossBattleRequest request) {

        return post(
                "/boss-battle/generate-content",
                request,
                BossBattleResponse.class
        );
    }

    public AiInterviewQuestionResponse generateAiInterviewQuestion(
            AiInterviewQuestionRequest request) {

        return post(
                "/interview/ai/question",
                request,
                AiInterviewQuestionResponse.class
        );
    }

    public AiInterviewEvaluateResponse evaluateInterviewAnswer(
            AiInterviewEvaluateRequest request) {

        return post(
                "/interview/evaluate",
                request,
                AiInterviewEvaluateResponse.class
        );
    }

    private <T> T post(
            String path,
            Object request,
            Class<T> responseType) {

        try {
            return restClient.post()
                    .uri(path)
                    .body(request)
                    .retrieve()
                    .body(responseType);

        } catch (RestClientException e) {
            throw new AiServiceException(
                    "FastAPI AI feature call failed for "
                            + path + ": " + e.getMessage(),
                    e
            );
        }
    }
}
