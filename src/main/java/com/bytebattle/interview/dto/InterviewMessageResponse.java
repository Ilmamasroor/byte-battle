package com.bytebattle.interview.dto;


import com.bytebattle.interview.enums.InterviewMessageRole;
import lombok.Builder;

import java.time.Instant;
import java.util.UUID;

@Builder
public record InterviewMessageResponse(
        UUID id,
        InterviewMessageRole role,
        String content,
        Integer sequenceNumber,
        Instant createdAt
) {}