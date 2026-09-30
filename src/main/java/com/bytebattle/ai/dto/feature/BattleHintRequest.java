package com.bytebattle.ai.dto.feature;

import java.util.Map;

public record BattleHintRequest(
        Map<String, Object> concept,
        String question,
        Map<String, Object> canonicalKnowledge,
        Integer hintLevel
) {}
