package com.bytebattle.onboarding;

import com.bytebattle.bytedna.ByteDNA;
import jakarta.validation.constraints.*;

import java.util.List;

/** The learner's answers to the onboarding questions; they become the baseline Byte DNA and learner profile. */
public record OnboardingRequest(
        @NotNull ByteDNA.TechnicalExperience technicalExperience,
        @NotBlank @Size(max = 30) String preferredLanguage,
        @NotBlank @Size(max = 200) String careerGoal,
        @NotNull ByteDNA.LearningStyle learningStyle,
        @NotNull ByteDNA.ExplanationStyle explanationStyle,
        @Size(max = 5) List<@NotBlank @Size(max = 40) String> interests,
        @NotNull @Min(5) @Max(600) Integer dailyGoalMinutes,
        @Size(max = 20) List<@NotBlank @Size(max = 80) String> confidenceAreas,   // topic slugs (optional)
        @Size(max = 20) List<@NotBlank @Size(max = 80) String> difficultyAreas    // topic slugs (optional)
) {
}
