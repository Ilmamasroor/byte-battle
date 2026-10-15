package com.bytebattle.ai.dto.personalization;

import java.util.List;
import java.util.UUID;

public record DiagnosisSummaryAiRequest(
        UUID userId,
        List<DiagnosisActivity> activities
) {
    public record DiagnosisActivity(
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
    ) {}

    /** Returns a copy bound to the authenticated user (top level and every activity). */
    public DiagnosisSummaryAiRequest withUserId(UUID userId) {
        java.util.List<DiagnosisActivity> bound = activities == null ? null : activities.stream()
                .map(a -> new DiagnosisActivity(userId, a.activityType(), a.accuracy(), a.score(),
                        a.attemptCount(), a.timeSpentSeconds(), a.hintsUsed(),
                        a.testCasesPassed(), a.testCasesTotal(), a.success()))
                .toList();
        return new DiagnosisSummaryAiRequest(userId, bound);
    }
}
