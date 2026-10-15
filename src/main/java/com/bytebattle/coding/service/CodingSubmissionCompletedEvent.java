package com.bytebattle.coding.service;

import com.bytebattle.coding.dto.ExecutionResult;

import java.util.UUID;

/** Published after a Judge0 result is persisted; consumed asynchronously (personalization, AI feedback). */
public record CodingSubmissionCompletedEvent(
        UUID submissionId,
        UUID userId,
        UUID challengeId,
        UUID conceptId,
        String challengeTitle,
        String difficulty,
        String language,
        String sourceCode,
        ExecutionResult result) {
}
