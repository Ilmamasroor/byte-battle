package com.bytebattle.learner.dto;

import com.bytebattle.learner.entity.LearnerProfile;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Size;

public class UpdateLearnerProfileRequestDTO {

    private LearnerProfile.ExperienceLevel experienceLevel;

    @Size(
        min = 2,
        max = 50,
        message = "Preferred language must be between 2 and 50 characters"
    )
    private String preferredLanguage;

    @Max(
        value = 1440,
        message = "Daily goal cannot exceed 1440 minutes"
    )
    private Integer dailyGoalMinutes;

    public UpdateLearnerProfileRequestDTO() {
    }

    public LearnerProfile.ExperienceLevel getExperienceLevel() {
        return experienceLevel;
    }

    public void setExperienceLevel(
            LearnerProfile.ExperienceLevel experienceLevel) {
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