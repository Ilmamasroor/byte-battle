package com.bytebattle.recommendation.dto;


import com.bytebattle.recommendation.enums.RecommendationPriority;
import com.bytebattle.recommendation.enums.RecommendationSource;
import com.bytebattle.recommendation.enums.RecommendationType;
import jakarta.validation.constraints.NotBlank;
import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.NotNull;

import java.util.UUID;

public record CreateRecommendationRequest(
        @JsonProperty(access = JsonProperty.Access.READ_ONLY) UUID userId,
        @NotNull UUID conceptId,
        @NotNull RecommendationType type,
        @NotNull RecommendationSource source,
        @NotNull RecommendationPriority priority,
        @NotBlank String title,
        String message,
        String reason,
        String expiresAt   // ISO-8601 string, optional
) {
    /** userId is never read from the request body; controllers set it from the authenticated user. */
    public CreateRecommendationRequest withUserId(UUID userId) {
        return new CreateRecommendationRequest(userId, conceptId, type, source, priority, title, message, reason, expiresAt);
    }
}
