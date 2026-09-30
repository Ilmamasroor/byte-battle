package com.bytebattle.performance.dto;

import com.bytebattle.performance.enums.ActivityType;
import lombok.Builder;

import java.time.Instant;
import java.util.UUID;

@Builder
public record PerformanceResponse(
        UUID id,
        String userId,
        UUID conceptId,
        ActivityType activityType,
        Integer score,
        Double accuracy,
        Integer timeSpentSeconds,
        Integer attemptCount,
        Boolean success,
        Integer hintsUsed,
        Integer testCasesPassed,
        Integer testCasesTotal,
        Instant createdAt
) {}