package com.bytebattle.ai.dto.feature;

import java.util.List;

public record CanonicalKnowledgeResponse(
        List<String> keyPoints,
        List<String> rules,
        List<String> examples
) {}
