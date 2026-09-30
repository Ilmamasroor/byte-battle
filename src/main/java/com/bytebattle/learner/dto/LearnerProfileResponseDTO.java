package com.bytebattle.learner.dto;

import java.time.Instant;

import com.bytebattle.learner.entity.LearnerProfile;

public class LearnerProfileResponseDTO {

    private String id;
    private String userId;
    private LearnerProfile.ExperienceLevel experienceLevel;
    private String preferredLanguage;
    private Integer dailyGoalMinutes;
    private Instant createdAt;
    private Instant updatedAt;

    public LearnerProfileResponseDTO() {
    }

    public LearnerProfileResponseDTO(
            String id,
            String userId,
            LearnerProfile.ExperienceLevel experienceLevel,
            String preferredLanguage,
            Integer dailyGoalMinutes,
            Instant createdAt,
            Instant updatedAt) {

        this.id = id;
        this.userId = userId;
        this.experienceLevel = experienceLevel;
        this.preferredLanguage = preferredLanguage;
        this.dailyGoalMinutes = dailyGoalMinutes;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }

    /**
     * Converts LearnerProfile entity into response DTO.
     */
    public static LearnerProfileResponseDTO fromEntity(LearnerProfile profile) {

        return new LearnerProfileResponseDTO(
                profile.getId() != null
                        ? profile.getId().toString()
                        : null,

                profile.getUser() != null
                        ? profile.getUser().getId()
                        : null,

                profile.getExperienceLevel(),

                profile.getPreferredLanguage(),

                profile.getDailyGoalMinutes(),

                profile.getCreatedAt(),

                profile.getUpdatedAt()
        );
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getUserId() {
        return userId;
    }

    public void setUserId(String userId) {
        this.userId = userId;
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

    public Instant getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Instant createdAt) {
        this.createdAt = createdAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(Instant updatedAt) {
        this.updatedAt = updatedAt;
    }
}