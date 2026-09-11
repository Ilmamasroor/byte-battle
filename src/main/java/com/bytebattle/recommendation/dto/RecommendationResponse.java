package com.bytebattle.recommendation.dto;


import com.bytebattle.recommendation.enums.RecommendationPriority;
import com.bytebattle.recommendation.enums.RecommendationSource;
import com.bytebattle.recommendation.enums.RecommendationType;
import lombok.Builder;

import java.time.Instant;
import java.util.UUID;

@Builder
public record RecommendationResponse(
        UUID id,
        UUID userId,
        UUID conceptId,
        RecommendationType type,
        RecommendationSource source,
        RecommendationPriority priority,
        String title,
        String message,
        String reason,
        Boolean isCompleted,
        Instant createdAt,
        Instant expiresAt
) {}