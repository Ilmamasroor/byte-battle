package com.bytebattle.ai.client;

import com.bytebattle.ai.dto.feature.*;
import com.bytebattle.ai.config.AiProperties;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

@Component
public class AiFeatureClient {

    private final RestClient restClient;
    private final AiProperties props;

    public AiFeatureClient(@Qualifier("aiRestClient") RestClient restClient, AiProperties props) {
        this.restClient = restClient;
        this.props = props;
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

    private <T> T post(String path, Object request, Class<T> responseType) {
        return AiHttp.post(restClient, props, path, request, responseType);
    }
}
