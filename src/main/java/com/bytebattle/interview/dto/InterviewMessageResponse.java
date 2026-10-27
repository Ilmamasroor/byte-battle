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
        Instant createdAt,
        /** On a USER message: its evaluation. On the assistant reply to sendMessage: the evaluation of the learner's last answer. */
        Integer score,
        String feedback,
        /** The five AI rubric dimensions (0-1) of the answer just evaluated; only on the reply to sendMessage. */
        java.util.Map<String, Double> rubric
) {}