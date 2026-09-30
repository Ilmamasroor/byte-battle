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
) {}
