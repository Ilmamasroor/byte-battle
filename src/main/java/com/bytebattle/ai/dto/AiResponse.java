package com.bytebattle.ai.dto;


import lombok.Builder;

import java.util.Map;

@Builder
public record AiResponse(
        boolean success,
        String operation,
        String content,
        Map<String, Object> metadata
) {}