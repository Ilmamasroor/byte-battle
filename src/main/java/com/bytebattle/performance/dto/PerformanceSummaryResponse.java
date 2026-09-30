package com.bytebattle.performance.dto;

import lombok.Builder;

import java.util.List;

@Builder
public record PerformanceSummaryResponse(
        double averageAccuracy,
        double averageScore,
        double successRate,
        int totalActivities,
        List<String> weakConcepts,
        List<String> strongConcepts,
        int totalHintsUsed,
        long totalTimeSpentSeconds
) {}