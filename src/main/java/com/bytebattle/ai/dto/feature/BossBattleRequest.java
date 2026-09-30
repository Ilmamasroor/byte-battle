package com.bytebattle.ai.dto.feature;

import java.util.Map;

public record BossBattleRequest(
        Map<String, Object> concept,
        Map<String, Object> canonicalKnowledge
) {}
