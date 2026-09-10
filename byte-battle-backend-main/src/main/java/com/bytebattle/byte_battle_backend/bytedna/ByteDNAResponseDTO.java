package com.bytebattle.byte_battle_backend.bytedna;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

public class ByteDNAResponseDTO {
    private UUID id;
    private UUID userId;
    private String learningStyle;
    private String strengthProfile;
    private String weaknessProfile;
    private ByteDNA.DifficultyLevel preferredDifficulty;
    private BigDecimal consistencyScore;
    private Instant createdAt;
    private Instant updatedAt;

    public ByteDNAResponseDTO() {
    }

    public ByteDNAResponseDTO(UUID id, UUID userId, String learningStyle, String strengthProfile,
                               String weaknessProfile, ByteDNA.DifficultyLevel preferredDifficulty,
                               BigDecimal consistencyScore, Instant createdAt, Instant updatedAt) {
        this.id = id;
        this.userId = userId;
        this.learningStyle = learningStyle;
        this.strengthProfile = strengthProfile;
        this.weaknessProfile = weaknessProfile;
        this.preferredDifficulty = preferredDifficulty;
        this.consistencyScore = consistencyScore;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }

    public static ByteDNAResponseDTO fromEntity(ByteDNA dna) {
        return new ByteDNAResponseDTO(
                dna.getId(),
                dna.getUser().getId(),
                dna.getLearningStyle(),
                dna.getStrengthProfile(),
                dna.getWeaknessProfile(),
                dna.getPreferredDifficulty(),
                dna.getConsistencyScore(),
                dna.getCreatedAt(),
                dna.getUpdatedAt()
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

    public String getLearningStyle() {
        return learningStyle;
    }

    public void setLearningStyle(String learningStyle) {
        this.learningStyle = learningStyle;
    }

    public String getStrengthProfile() {
        return strengthProfile;
    }

    public void setStrengthProfile(String strengthProfile) {
        this.strengthProfile = strengthProfile;
    }

    public String getWeaknessProfile() {
        return weaknessProfile;
    }

    public void setWeaknessProfile(String weaknessProfile) {
        this.weaknessProfile = weaknessProfile;
    }

    public ByteDNA.DifficultyLevel getPreferredDifficulty() {
        return preferredDifficulty;
    }

    public void setPreferredDifficulty(ByteDNA.DifficultyLevel preferredDifficulty) {
        this.preferredDifficulty = preferredDifficulty;
    }

    public BigDecimal getConsistencyScore() {
        return consistencyScore;
    }

    public void setConsistencyScore(BigDecimal consistencyScore) {
        this.consistencyScore = consistencyScore;
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