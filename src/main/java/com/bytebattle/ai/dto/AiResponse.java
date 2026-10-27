package com.bytebattle.ai.dto;


import lombok.Builder;

import java.util.Map;

/**
 * Shared AI envelope. {@code fallback=true} means this response was produced locally because the
 * AI service was disabled or unavailable (always together with success=false).
 */
@Builder
public record AiResponse(
        boolean success,
        String operation,
        String content,
        Map<String, Object> metadata,
        boolean fallback
) {}
