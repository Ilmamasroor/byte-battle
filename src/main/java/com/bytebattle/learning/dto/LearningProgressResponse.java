package com.bytebattle.learning.dto;


import com.bytebattle.learning.enums.LearningStage;
import lombok.Builder;

import java.time.Instant;
import java.util.UUID;

@Builder
public record LearningProgressResponse(
        UUID id,
        UUID userId,
        UUID conceptId,
        LearningStage currentStage,
        Boolean completed,
        Integer progressPercentage,
        Instant startedAt,
        Instant completedAt
) {}