package com.bytebattle.byte_battle_backend.bytedna;

public class UpdateByteDNARequestDTO {

    // All optional - only non-null fields get applied
    private String learningStyle;
    private String strengthProfile;
    private String weaknessProfile;
    private ByteDNA.DifficultyLevel preferredDifficulty;

    public UpdateByteDNARequestDTO() {
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