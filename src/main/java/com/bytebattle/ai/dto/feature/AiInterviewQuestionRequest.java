package com.bytebattle.ai.dto.feature;

import java.util.List;
import java.util.Map;

public record AiInterviewQuestionRequest(
        Map<String, Object> concept,
        Map<String, Object> canonicalKnowledge,
        List<Object> conversationHistory
) {}
