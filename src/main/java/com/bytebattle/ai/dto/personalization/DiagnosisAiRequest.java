package com.bytebattle.ai.dto.personalization;

import java.util.UUID;

public record DiagnosisAiRequest(
        UUID userId,
        String activityType,
        Double accuracy,
        Integer score,
        Integer attemptCount,
        Integer timeSpentSeconds,
        Integer hintsUsed,
        Integer testCasesPassed,
        Integer testCasesTotal,
        Boolean success
) {
    /** Returns a copy bound to the authenticated user; client-supplied userId must never be trusted. */
    public DiagnosisAiRequest withUserId(UUID userId) {
        return new DiagnosisAiRequest(userId, activityType, accuracy, score, attemptCount, timeSpentSeconds, hintsUsed, testCasesPassed, testCasesTotal, success);
    }
}
