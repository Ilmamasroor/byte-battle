package com.bytebattle.ai.dto.feature;

import java.util.Map;

public record AnalogyRequest(
        Map<String, Object> concept,
        Map<String, Object> canonicalKnowledge,
        Map<String, Object> byteDNA
) {}
