package com.bytebattle.bytedna;

import com.bytebattle.user.User;
import jakarta.persistence.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Entity
@Table(name = "byte_dna")
public class ByteDNA {

    @Id
    @GeneratedValue
    private UUID id;

    @OneToOne
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(name = "technical_experience", nullable = false)
    private TechnicalExperience technicalExperience;

    @Column(name = "career_goal")
    private String careerGoal;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(columnDefinition = "jsonb")
    private List<String> interests;

    @Column(name = "preferred_language", nullable = false)
    private String preferredLanguage;

    @Enumerated(EnumType.STRING)
    @Column(name = "learning_preferences")
    private LearningStyle learningPreferences;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "confidence_areas", columnDefinition = "jsonb")
    private List<String> confidenceAreas;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "difficulty_areas", columnDefinition = "jsonb")
    private List<String> difficultyAreas;

    @Enumerated(EnumType.STRING)
    @Column(name = "explanation_preferences")
    private ExplanationStyle explanationPreferences;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "repeated_mistakes", columnDefinition = "jsonb")
    private List<String> repeatedMistakes;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "topic_accuracy", columnDefinition = "jsonb")
    private Map<String, Object> topicAccuracy;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "difficulty_progression", columnDefinition = "jsonb")
    private Map<String, Object> difficultyProgression;

    @Column(name = "created_at", updatable = false)
    private Instant createdAt = Instant.now();

    @Column(name = "updated_at")
    private Instant updatedAt = Instant.now();

    public enum TechnicalExperience {
        BEGINNER, INTERMEDIATE, ADVANCED
    }

    public enum LearningStyle {
        INTERVEIW_PREP, EXAM_READY, CONCEPTUAL_DEPTH, AUDITORY
    }

    public enum ExplanationStyle {
        STORY,FUN,CINEMATIC,
    }

    public ByteDNA() {
    }

    @PreUpdate
    public void preUpdate() {
        this.updatedAt = Instant.now();
    }

    // ===== Getters and Setters =====
    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }

    public TechnicalExperience getTechnicalExperience() { return technicalExperience; }
    public void setTechnicalExperience(TechnicalExperience technicalExperience) { this.technicalExperience = technicalExperience; }

    public String getCareerGoal() { return careerGoal; }
    public void setCareerGoal(String careerGoal) { this.careerGoal = careerGoal; }

    public List<String> getInterests() { return interests; }
    public void setInterests(List<String> interests) { this.interests = interests; }

    public String getPreferredLanguage() { return preferredLanguage; }
    public void setPreferredLanguage(String preferredLanguage) { this.preferredLanguage = preferredLanguage; }

    public LearningStyle getLearningPreferences() { return learningPreferences; }
    public void setLearningPreferences(LearningStyle learningPreferences) { this.learningPreferences = learningPreferences; }

    public List<String> getConfidenceAreas() { return confidenceAreas; }
    public void setConfidenceAreas(List<String> confidenceAreas) { this.confidenceAreas = confidenceAreas; }

    public List<String> getDifficultyAreas() { return difficultyAreas; }
    public void setDifficultyAreas(List<String> difficultyAreas) { this.difficultyAreas = difficultyAreas; }

    public ExplanationStyle getExplanationPreferences() { return explanationPreferences; }
    public void setExplanationPreferences(ExplanationStyle explanationPreferences) { this.explanationPreferences = explanationPreferences; }

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