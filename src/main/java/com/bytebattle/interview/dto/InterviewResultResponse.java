package com.bytebattle.interview.dto;


import lombok.Builder;

import java.util.UUID;

@Builder
public record InterviewResultResponse(
        UUID sessionId,
        Integer score,
        Integer totalMessages,
        String status
) {}