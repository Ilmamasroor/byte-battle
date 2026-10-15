package com.bytebattle.ai.client;

import com.bytebattle.ai.dto.personalization.*;
import com.bytebattle.ai.config.AiProperties;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

@Component
public class PersonalizationAiClient {

    private final RestClient restClient;
    private final AiProperties props;

    public PersonalizationAiClient(@Qualifier("personalizationRestClient") RestClient restClient,
                                   AiProperties props) {
        this.restClient = restClient;
        this.props = props;
    }

    public ByteDnaAiResponse onboard(OnboardingAiRequest request) {
        return post("/onboarding", request, ByteDnaAiResponse.class);
    }

    public DiagnosisAiResponse diagnose(DiagnosisAiRequest request) {
        return post("/diagnose", request, DiagnosisAiResponse.class);
    }

    public DiagnosisSummaryAiResponse diagnoseSummary(
            DiagnosisSummaryAiRequest request) {

        return post(
                "/diagnose/summary",
                request,
                DiagnosisSummaryAiResponse.class
        );
    }

    public ByteDnaEvolutionResponse evolveByteDna(
            ByteDnaEvolutionRequest request) {

        return post(
                "/byte-dna/evolve",
                request,
                ByteDnaEvolutionResponse.class
        );
    }

    public RecommendationAiResponse recommend(
            RecommendationAiRequest request) {

        return post(
                "/recommend",
                request,
                RecommendationAiResponse.class
        );
    }

    private <T> T post(String path, Object request, Class<T> responseType) {
        return AiHttp.post(restClient, props, path, request, responseType);
    }
}
