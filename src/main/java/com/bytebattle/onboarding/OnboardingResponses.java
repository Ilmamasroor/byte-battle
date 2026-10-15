package com.bytebattle.onboarding;

import java.util.List;

public final class OnboardingResponses {

    private OnboardingResponses() {
    }

    public record Status(boolean completed, boolean hasLearnerProfile, boolean hasByteDna) {
    }

    public record Result(
            boolean completed,
            String technicalExperience,
            String preferredLanguage,
            String careerGoal,
            String learningStyle,
            String explanationStyle,
            List<String> interests,
            int dailyGoalMinutes,
            List<String> confidenceAreas,
            List<String> difficultyAreas) {
    }
}
