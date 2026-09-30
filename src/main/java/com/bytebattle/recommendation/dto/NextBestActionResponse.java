package com.bytebattle.recommendation.dto;

import com.bytebattle.recommendation.enums.RecommendationActivityType;
import com.bytebattle.recommendation.enums.RecommendationPriority;

import java.util.UUID;

/**
 * Represents the single action the learner should perform next.
 *
 * Flutter should display this response.
 * Flutter must not calculate the next action itself.
 */
public record NextBestActionResponse(

        UUID recommendationId,

        UUID conceptId,

        String conceptName,

        RecommendationActivityType activityType,

        RecommendationPriority priority,

        String title,

        String reason

) {
}