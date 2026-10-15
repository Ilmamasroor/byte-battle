package com.bytebattle.ai.dto.personalization;

import java.util.List;
import java.util.UUID;

public record OnboardingAiRequest(
        UUID userId,
        String technicalExperience,
        String preferredLanguage,
        String careerGoal,
        String learningStyle,
        String explanationStyle,
        List<String> interests
) {
    /** Returns a copy bound to the authenticated user; client-supplied userId must never be trusted. */
    public OnboardingAiRequest withUserId(UUID userId) {
        return new OnboardingAiRequest(userId, technicalExperience, preferredLanguage, careerGoal, learningStyle, explanationStyle, interests);
    }
}
