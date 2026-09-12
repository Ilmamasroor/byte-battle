package com.bytebattle.performance.dto;

import com.bytebattle.performance.enums.ActivityType;
import jakarta.validation.constraints.NotNull;

import java.util.UUID;

public record CreatePerformanceRecordRequest(
        @NotNull UUID userId,
        @NotNull UUID conceptId,
        @NotNull ActivityType activityType,
        @NotNull Integer score,
        @NotNull Double accuracy,
        @NotNull Integer timeSpentSeconds,
        @NotNull Integer attemptCount,
        @NotNull Boolean success
) {}