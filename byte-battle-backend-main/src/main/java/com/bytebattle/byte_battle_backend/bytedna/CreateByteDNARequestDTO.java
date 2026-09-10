package com.bytebattle.byte_battle_backend.bytedna;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public class CreateByteDNARequestDTO {

    @NotBlank(message = "Learning style is required")
    private String learningStyle;

    private String strengthProfile;  // raw JSON string, optional
    private String weaknessProfile;  // raw JSON string, optional

    @NotNull(message = "Preferred difficulty is required")
    private ByteDNA.DifficultyLevel preferredDifficulty;

    public CreateByteDNARequestDTO() {
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
}