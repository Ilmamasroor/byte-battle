package com.bytebattle.byte_battle_backend.bytedna;

import com.bytebattle.byte_battle_backend.user.User;
import jakarta.persistence.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "byte_dna")
public class ByteDNA {

    @Id
    @GeneratedValue
    private UUID id;

    // One-to-one: each User has exactly one ByteDNA profile
    @OneToOne
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;

    @Column(name = "learning_style", nullable = false)
    private String learningStyle;

    // Stored as raw JSON text in a JSONB column - flexible structure,
    // exact shape not frozen yet per the architecture doc.
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "strength_profile", columnDefinition = "jsonb")
    private String strengthProfile;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "weakness_profile", columnDefinition = "jsonb")
    private String weaknessProfile;

    @Enumerated(EnumType.STRING)
    @Column(name = "preferred_difficulty", nullable = false)
    private DifficultyLevel preferredDifficulty;

    @Column(name = "consistency_score", nullable = false, precision = 5, scale = 2)
    private BigDecimal consistencyScore = BigDecimal.ZERO;

    @Column(name = "created_at", updatable = false)
    private Instant createdAt = Instant.now();

    @Column(name = "updated_at")
    private Instant updatedAt = Instant.now();

    public enum DifficultyLevel {
        EASY, MEDIUM, HARD
    }

    public ByteDNA() {
    }

    @PreUpdate
    public void preUpdate() {
        this.updatedAt = Instant.now();
    }

    // ===== Getters and Setters =====
    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public User getUser() {
        return user;
    }

    public void setUser(User user) {
        this.user = user;
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

    public DifficultyLevel getPreferredDifficulty() {
        return preferredDifficulty;
    }

    public void setPreferredDifficulty(DifficultyLevel preferredDifficulty) {
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