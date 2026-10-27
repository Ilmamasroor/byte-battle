package com.bytebattle.ai.service;


import com.bytebattle.ai.client.LlmClient;
import com.bytebattle.ai.dto.AiRequest;
import com.bytebattle.ai.dto.AiResponse;
import com.bytebattle.ai.exception.AiServiceException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.Map;

@Service
public class AiService {

    private static final Logger log = LoggerFactory.getLogger(AiService.class);

    private final LlmClient llmClient;

    public AiService(LlmClient llmClient) {
        this.llmClient = llmClient;
    }

    /**
     * Central entry point. AI failures NEVER propagate as errors to callers —
     * doc §41: AI unavailable -> fallback response -> core app continues.
     */
    public AiResponse process(AiRequest request) {
        try {
            return llmClient.call(request);
        } catch (AiServiceException e) {
            log.warn("AI call failed (operation={}, code={}); returning fallback", request.operation(), e.getCode());
            return fallback(request, e.getCode());
        }
    }

    private AiResponse fallback(AiRequest request, String code) {
        return AiResponse.builder()
                .success(false)
                .fallback(true)
                .operation(request.operation())
                .content("AI explanation is temporarily unavailable. Core progress is unaffected.")
                .metadata(Map.of("fallback", true, "code", code == null ? "AI_UNAVAILABLE" : code))
                .build();
    }
}
