package com.bytebattle.ai.client;


import com.bytebattle.ai.dto.AiRequest;
import com.bytebattle.ai.dto.AiResponse;
import com.bytebattle.ai.exception.AiServiceException;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

// Real implementation — talks to the separate Python FastAPI service (doc §37).
// Not registered as @Primary yet; wire this in over StubLlmClient once FastAPI is live.
@Component
public class FastApiLlmClient implements LlmClient {

    private final RestClient restClient;

    public FastApiLlmClient(@Value("${bytebattle.ai.base-url}") String baseUrl,
                             @Value("${bytebattle.ai.timeout-ms}") int timeoutMs) {
        this.restClient = RestClient.builder().baseUrl(baseUrl).build();
    }

    @Override
    public AiResponse call(AiRequest request) {
        try {
            return restClient.post()
                    .uri("/ai/process")
                    .body(request)
                    .retrieve()
                    .body(AiResponse.class);
        } catch (RestClientException e) {
            throw new AiServiceException("FastAPI call failed: " + e.getMessage(), e);
        }
    }
}