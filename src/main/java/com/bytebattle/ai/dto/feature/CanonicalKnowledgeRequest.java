package com.bytebattle.ai.dto.feature;

import java.util.Map;

public record CanonicalKnowledgeRequest(
        Map<String, Object> concept
) {}
