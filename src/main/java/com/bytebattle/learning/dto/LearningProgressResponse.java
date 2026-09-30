package com.bytebattle.learning.dto;

import com.bytebattle.learning.enums.LearningStage;
import lombok.Builder;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Builder
public record LearningProgressResponse(

        UUID id,

        String userId,

        UUID conceptId,

        LearningStage currentStage,

        Boolean completed,

        Integer progressPercentage,

        Instant startedAt,

        Instant completedAt,

        List<String> completedStages
) {
}