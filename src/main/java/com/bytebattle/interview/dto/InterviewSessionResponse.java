package com.bytebattle.interview.dto;


import com.bytebattle.interview.enums.InterviewStatus;
import lombok.Builder;

import java.time.Instant;
import java.util.UUID;

@Builder
public record InterviewSessionResponse(
        UUID id,
        UUID userId,
        UUID conceptId,
        InterviewStatus status,
        String difficulty,
        Instant startedAt,
        Instant completedAt,
        Integer score
) {}
