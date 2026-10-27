package com.bytebattle.ai.dto.feature;

import java.util.Map;

public record AiInterviewEvaluateRequest(
        Map<String, Object> concept,
        Map<String, Object> canonicalKnowledge,
        String question,
        String learnerAnswer
) {}
