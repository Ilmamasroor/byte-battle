package com.bytebattle.recommendation.dto;


import com.bytebattle.recommendation.enums.RecommendationPriority;
import com.bytebattle.recommendation.enums.RecommendationSource;
import com.bytebattle.recommendation.enums.RecommendationType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.util.UUID;

public record CreateRecommendationRequest(
        @NotNull UUID userId,
        @NotNull UUID conceptId,
        @NotNull RecommendationType type,
        @NotNull RecommendationSource source,
        @NotNull RecommendationPriority priority,
        @NotBlank String title,
        String message,
        String reason,
        String expiresAt   // ISO-8601 string, optional
) {}
