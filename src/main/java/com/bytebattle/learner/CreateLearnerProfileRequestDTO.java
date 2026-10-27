package com.bytebattle.learner;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

public class CreateLearnerProfileRequestDTO {

    @NotNull(message = "Experience level is required")
    private LearnerProfile.ExperienceLevel experienceLevel;

    @NotBlank(message = "Preferred language is required")
    private String preferredLanguage;

    @NotNull(message = "Daily goal minutes is required")
    @Positive(message = "Daily goal minutes must be positive")
    private Integer dailyGoalMinutes;

    public CreateLearnerProfileRequestDTO() {
    }

    public LearnerProfile.ExperienceLevel getExperienceLevel() {
        return experienceLevel;
    }

    public void setExperienceLevel(LearnerProfile.ExperienceLevel experienceLevel) {
        this.experienceLevel = experienceLevel;
    }

    public String getPreferredLanguage() {
        return preferredLanguage;
    }

    public void setPreferredLanguage(String preferredLanguage) {
        this.preferredLanguage = preferredLanguage;
    }

    public Integer getDailyGoalMinutes() {
        return dailyGoalMinutes;
    }

    public void setDailyGoalMinutes(Integer dailyGoalMinutes) {
        this.dailyGoalMinutes = dailyGoalMinutes;
    }
}