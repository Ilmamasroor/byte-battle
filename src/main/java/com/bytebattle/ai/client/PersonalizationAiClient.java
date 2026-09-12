package com.bytebattle.ai.client;

import com.bytebattle.ai.dto.personalization.*;
import com.bytebattle.ai.exception.AiServiceException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

@Component
public class PersonalizationAiClient {

    private final RestClient restClient;

    public PersonalizationAiClient(
            @Value("${bytebattle.ai.personalization.base-url:http://localhost:8000}") String baseUrl) {

        this.restClient = RestClient.builder()
                .baseUrl(baseUrl)
                .build();
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
                    "FastAPI personalization call failed for "
                            + path + ": " + e.getMessage(),
                    e
            );
        }
    }
}
