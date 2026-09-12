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
}
