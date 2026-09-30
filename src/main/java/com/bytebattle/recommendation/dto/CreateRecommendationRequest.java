package com.bytebattle.recommendation.dto;

import com.bytebattle.recommendation.enums.RecommendationPriority;
import com.bytebattle.recommendation.enums.RecommendationSource;
import com.bytebattle.recommendation.enums.RecommendationType;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.UUID;

public record CreateRecommendationRequest(

        /*
         * ADMIN / INTERNAL USE ONLY
         *
         * This userId identifies the learner who should receive
         * the recommendation.
         *
         * This endpoint must NOT be exposed to normal learners.
         */
        @NotBlank
        @Size(max = 36)
        String userId,

        @NotNull
        UUID conceptId,

        @NotNull
        RecommendationType type,

        @NotNull
        RecommendationSource source,

        @NotNull
        RecommendationPriority priority,

        @NotBlank
        @Size(max = 255)
        String title,

        @Size(max = 5000)
        String message,

        @Size(max = 5000)
        String reason,

        /*
         * ISO-8601 Instant.
         *
         * Example:
         * 2026-12-31T00:00:00Z
         *
         * Optional.
         */
        String expiresAt

) {
}