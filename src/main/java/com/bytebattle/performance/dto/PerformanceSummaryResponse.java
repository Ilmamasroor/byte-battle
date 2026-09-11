package com.bytebattle.performance.dto;


import lombok.Builder;

import java.util.List;

@Builder
public record PerformanceSummaryResponse(
        Double averageAccuracy,
        Double averageScore,
        Double successRate,
        Integer totalActivities,
        List<String> weakConcepts,
        List<String> strongConcepts
) {}