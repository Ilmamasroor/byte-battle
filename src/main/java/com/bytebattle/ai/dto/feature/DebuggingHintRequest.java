package com.bytebattle.ai.dto.feature;

import java.util.Map;

public record DebuggingHintRequest(
        Map<String, Object> concept,
        Map<String, Object> diagnosis,
        Integer hintLevel
) {}
