package com.bytebattle.ai.dto.personalization;

import java.util.UUID;

public record RecommendationAiResponse(
        UUID userId,
        String topic,
        String targetErrorCategory,
        String recommendedChallengeType,
        String reason,
        String basis
) {}
