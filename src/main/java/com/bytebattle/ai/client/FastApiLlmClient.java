package com.bytebattle.ai.client;

import com.bytebattle.ai.dto.AiRequest;
import com.bytebattle.ai.dto.AiResponse;
import com.bytebattle.ai.exception.AiServiceException;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.client.JdkClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

import java.net.http.HttpClient;
import java.time.Duration;

// Real implementation — talks to the separate Python FastAPI service (doc §37).
@Component
public class FastApiLlmClient implements LlmClient {

    private final RestClient restClient;

    public FastApiLlmClient(@Value("${bytebattle.ai.base-url:http://localhost:8000}") String baseUrl,
                             @Value("${bytebattle.ai.timeout-ms:5000}") int timeoutMs) {

        // CHANGED: timeoutMs is now actually applied
        JdkClientHttpRequestFactory factory = new JdkClientHttpRequestFactory(
                HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(3)).build());
        factory.setReadTimeout(Duration.ofMillis(timeoutMs));

        this.restClient = RestClient.builder()
                .baseUrl(baseUrl)
                .requestFactory(factory)
                .build();
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