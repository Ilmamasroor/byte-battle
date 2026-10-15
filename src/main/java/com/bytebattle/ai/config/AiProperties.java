package com.bytebattle.ai.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/** Typed view of the bytebattle.ai.* properties (single source of truth for AI wiring). */
@Component
public class AiProperties {

    private final String baseUrl;
    private final String personalizationBaseUrl;
    private final boolean enabled;
    private final int connectTimeoutMs;
    private final int readTimeoutMs;

    public AiProperties(
            @Value("${bytebattle.ai.base-url:http://localhost:8000}") String baseUrl,
            @Value("${bytebattle.ai.personalization.base-url:${bytebattle.ai.base-url:http://localhost:8000}}")
            String personalizationBaseUrl,
            @Value("${bytebattle.ai.enabled:true}") boolean enabled,
            @Value("${bytebattle.ai.connect-timeout-ms:2000}") int connectTimeoutMs,
            @Value("${bytebattle.ai.read-timeout-ms:20000}") int readTimeoutMs) {
        this.baseUrl = baseUrl;
        this.personalizationBaseUrl = personalizationBaseUrl;
        this.enabled = enabled;
        this.connectTimeoutMs = connectTimeoutMs;
        this.readTimeoutMs = readTimeoutMs;
    }

    public String baseUrl() { return baseUrl; }
    public String personalizationBaseUrl() { return personalizationBaseUrl; }
    public boolean enabled() { return enabled; }
    public int connectTimeoutMs() { return connectTimeoutMs; }
    public int readTimeoutMs() { return readTimeoutMs; }
}
