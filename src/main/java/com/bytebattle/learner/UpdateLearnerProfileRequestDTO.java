package com.bytebattle.learner;

import jakarta.validation.constraints.Positive;

public class UpdateLearnerProfileRequestDTO {

    // All optional on update - only non-null fields get applied
    private LearnerProfile.ExperienceLevel experienceLevel;
    private String preferredLanguage;

    @Positive(message = "Daily goal minutes must be positive")
    private Integer dailyGoalMinutes;

    public UpdateLearnerProfileRequestDTO() {
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