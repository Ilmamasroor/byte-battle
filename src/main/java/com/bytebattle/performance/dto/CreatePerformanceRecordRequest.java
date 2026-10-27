package com.bytebattle.performance.dto;

import com.bytebattle.performance.enums.ActivityType;
import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.NotNull;

import java.util.UUID;

public record CreatePerformanceRecordRequest(
        @JsonProperty(access = JsonProperty.Access.READ_ONLY) UUID userId,
        @NotNull UUID conceptId,
        @NotNull ActivityType activityType,
        @NotNull Integer score,
        @NotNull Double accuracy,
        @NotNull Integer timeSpentSeconds,
        @NotNull Integer attemptCount,
        @NotNull Boolean success
) {
    /** userId is never read from the request body; controllers set it from the authenticated user. */
    public CreatePerformanceRecordRequest withUserId(UUID userId) {
        return new CreatePerformanceRecordRequest(userId, conceptId, activityType, score, accuracy, timeSpentSeconds, attemptCount, success);
    }
}
