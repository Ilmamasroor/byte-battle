package com.bytebattle.ai.config;

import com.bytebattle.ai.exception.AiServiceException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.client.ClientHttpRequestFactory;
import org.springframework.http.client.JdkClientHttpRequestFactory;
import org.springframework.web.client.RestClient;

import java.io.IOException;
import java.net.http.HttpClient;
import java.time.Duration;

/**
 * Builds every RestClient used to talk to the Python AI service from one place, so connect/read
 * timeouts and error mapping are consistent. 4xx/5xx responses carrying Python's structured
 * {code, message} body become a typed {@link AiServiceException}.
 */
@Configuration
public class AiHttpConfig {

    @Bean
    public ClientHttpRequestFactory aiClientHttpRequestFactory(AiProperties props) {
        return createRequestFactory(props);
    }

    @Bean
    public RestClient aiRestClient(ClientHttpRequestFactory aiClientHttpRequestFactory,
                                   AiProperties props, ObjectMapper objectMapper) {
        return buildClient(aiClientHttpRequestFactory, props.baseUrl(), objectMapper);
    }

    @Bean
    public RestClient personalizationRestClient(ClientHttpRequestFactory aiClientHttpRequestFactory,
                                                AiProperties props, ObjectMapper objectMapper) {
        return buildClient(aiClientHttpRequestFactory, props.personalizationBaseUrl(), objectMapper);
    }

    public static JdkClientHttpRequestFactory createRequestFactory(AiProperties props) {
        HttpClient httpClient = HttpClient.newBuilder()
                .version(HttpClient.Version.HTTP_1_1)
                .connectTimeout(Duration.ofMillis(props.connectTimeoutMs()))
                .build();
        JdkClientHttpRequestFactory factory = new JdkClientHttpRequestFactory(httpClient);
        factory.setReadTimeout(Duration.ofMillis(props.readTimeoutMs()));
        return factory;
    }

    public static RestClient buildClient(ClientHttpRequestFactory factory, String baseUrl, ObjectMapper objectMapper) {
        return RestClient.builder()
                .baseUrl(baseUrl)
                .requestFactory(factory)
                .defaultStatusHandler(status -> status.isError(), (request, response) -> {
                    byte[] raw;
                    try {
                        raw = response.getBody().readAllBytes();
                    } catch (IOException e) {
                        raw = new byte[0];
                    }
                    throw toException(response.getStatusCode().value(), raw, objectMapper);
                })
                .build();
    }

    /** Parses {code,message} (optionally nested under FastAPI's "detail") from an error body. */
    public static AiServiceException toException(int status, byte[] body, ObjectMapper objectMapper) {
        String code = "AI_HTTP_" + status;
        String message = "AI service returned HTTP " + status;
        try {
            if (body != null && body.length > 0) {
                JsonNode root = objectMapper.readTree(body);
                JsonNode node = root.has("detail") && root.get("detail").isObject() ? root.get("detail") : root;
                if (node.hasNonNull("code")) {
                    code = node.get("code").asText();
                }
                if (node.hasNonNull("message")) {
                    message = node.get("message").asText();
                } else if (root.hasNonNull("detail") && root.get("detail").isTextual()) {
                    message = root.get("detail").asText();
                }
            }
        } catch (IOException | RuntimeException ignored) {
            // non-JSON body: keep the generic code/message
        }
        return new AiServiceException(code, status, message);
    }
}
