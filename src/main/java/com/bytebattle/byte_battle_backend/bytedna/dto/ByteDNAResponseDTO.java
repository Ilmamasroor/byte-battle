package com.bytebattle.byte_battle_backend.bytedna.dto;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import com.bytebattle.byte_battle_backend.bytedna.ByteDNA;

public class ByteDNAResponseDTO {
    private UUID id;
    private UUID userId;
    private ByteDNA.TechnicalExperience technicalExperience;
    private String careerGoal;
    private List<String> interests;
    private String preferredLanguage;
    private ByteDNA.LearningStyle learningPreferences;
    private List<String> confidenceAreas;
    private List<String> difficultyAreas;
    private ByteDNA.ExplanationStyle explanationPreferences;
    private List<String> repeatedMistakes;
    private Map<String, Object> topicAccuracy;
    private Map<String, Object> difficultyProgression;
    private Instant createdAt;
    private Instant updatedAt;

    public ByteDNAResponseDTO() {
    }

    public static ByteDNAResponseDTO fromEntity(ByteDNA dna) {
        ByteDNAResponseDTO dto = new ByteDNAResponseDTO();
        dto.id = dna.getId();
        dto.userId = dna.getUser().getId();
        dto.technicalExperience = dna.getTechnicalExperience();
        dto.careerGoal = dna.getCareerGoal();
        dto.interests = dna.getInterests();
        dto.preferredLanguage = dna.getPreferredLanguage();
        dto.learningPreferences = dna.getLearningPreferences();
        dto.confidenceAreas = dna.getConfidenceAreas();
        dto.difficultyAreas = dna.getDifficultyAreas();
        dto.explanationPreferences = dna.getExplanationPreferences();
        dto.repeatedMistakes = dna.getRepeatedMistakes();
        dto.topicAccuracy = dna.getTopicAccuracy();
        dto.difficultyProgression = dna.getDifficultyProgression();
        dto.createdAt = dna.getCreatedAt();
        dto.updatedAt = dna.getUpdatedAt();
        return dto;
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public UUID getUserId() { return userId; }
    public void setUserId(UUID userId) { this.userId = userId; }

    public ByteDNA.TechnicalExperience getTechnicalExperience() { return technicalExperience; }
    public void setTechnicalExperience(ByteDNA.TechnicalExperience technicalExperience) { this.technicalExperience = technicalExperience; }

    public String getCareerGoal() { return careerGoal; }
    public void setCareerGoal(String careerGoal) { this.careerGoal = careerGoal; }

    public List<String> getInterests() { return interests; }
    public void setInterests(List<String> interests) { this.interests = interests; }

    public String getPreferredLanguage() { return preferredLanguage; }
    public void setPreferredLanguage(String preferredLanguage) { this.preferredLanguage = preferredLanguage; }

    public ByteDNA.LearningStyle getLearningPreferences() { return learningPreferences; }
    public void setLearningPreferences(ByteDNA.LearningStyle learningPreferences) { this.learningPreferences = learningPreferences; }

    public List<String> getConfidenceAreas() { return confidenceAreas; }
    public void setConfidenceAreas(List<String> confidenceAreas) { this.confidenceAreas = confidenceAreas; }

    public List<String> getDifficultyAreas() { return difficultyAreas; }
    public void setDifficultyAreas(List<String> difficultyAreas) { this.difficultyAreas = difficultyAreas; }

    public ByteDNA.ExplanationStyle getExplanationPreferences() { return explanationPreferences; }
    public void setExplanationPreferences(ByteDNA.ExplanationStyle explanationPreferences) { this.explanationPreferences = explanationPreferences; }

    public List<String> getRepeatedMistakes() { return repeatedMistakes; }
    public void setRepeatedMistakes(List<String> repeatedMistakes) { this.repeatedMistakes = repeatedMistakes; }

    public Map<String, Object> getTopicAccuracy() { return topicAccuracy; }
    public void setTopicAccuracy(Map<String, Object> topicAccuracy) { this.topicAccuracy = topicAccuracy; }

    public Map<String, Object> getDifficultyProgression() { return difficultyProgression; }
    public void setDifficultyProgression(Map<String, Object> difficultyProgression) { this.difficultyProgression = difficultyProgression; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }

    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
}