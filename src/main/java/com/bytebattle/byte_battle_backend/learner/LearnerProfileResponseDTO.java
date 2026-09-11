package com.bytebattle.byte_battle_backend.learner;

import java.time.Instant;
import java.util.UUID;

public class LearnerProfileResponseDTO {
    private UUID id;
    private UUID userId;
    private LearnerProfile.ExperienceLevel experienceLevel;
    private String preferredLanguage;
    private Integer dailyGoalMinutes;
    private Instant createdAt;
    private Instant updatedAt;

    public LearnerProfileResponseDTO() {
    }

    public LearnerProfileResponseDTO(UUID id, UUID userId, LearnerProfile.ExperienceLevel experienceLevel,
                                      String preferredLanguage, Integer dailyGoalMinutes,
                                      Instant createdAt, Instant updatedAt) {
        this.id = id;
        this.userId = userId;
        this.experienceLevel = experienceLevel;
        this.preferredLanguage = preferredLanguage;
        this.dailyGoalMinutes = dailyGoalMinutes;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }

    public static LearnerProfileResponseDTO fromEntity(LearnerProfile profile) {
        return new LearnerProfileResponseDTO(
                profile.getId(),
                profile.getUser().getId(),
                profile.getExperienceLevel(),
                profile.getPreferredLanguage(),
                profile.getDailyGoalMinutes(),
                profile.getCreatedAt(),
                profile.getUpdatedAt()
        );
    }

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public UUID getUserId() {
        return userId;
    }

    public void setUserId(UUID userId) {
        this.userId = userId;
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