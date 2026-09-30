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
) {}
