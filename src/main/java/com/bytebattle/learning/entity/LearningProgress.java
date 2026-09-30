package com.bytebattle.learning.entity;

import com.bytebattle.learning.enums.LearningStage;
import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;

@Entity
@Table(
        name = "learning_progress",

        indexes = {
                @Index(
                        name = "idx_learning_user",
                        columnList = "user_id"
                ),
                @Index(
                        name = "idx_learning_user_concept",
                        columnList = "user_id, concept_id"
                )
        },

        uniqueConstraints = {
                @UniqueConstraint(
                        name = "uk_learning_user_concept",
                        columnNames = {
                                "user_id",
                                "concept_id"
                        }
                )
        }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LearningProgress {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    /**
     * Owner of this learning progress.
     *
     * This value must come from the authenticated user,
     * not from client-controlled request data.
     */
    @Column(
            name = "user_id",
            nullable = false
    )
    private String userId;

    @Column(
            name = "concept_id",
            nullable = false
    )
    private UUID conceptId;

    @Enumerated(EnumType.STRING)
    @Column(
            name = "current_stage",
            nullable = false
    )
    private LearningStage currentStage;

    @Column(
            nullable = false
    )
    private Boolean completed;

    @Column(
            nullable = false
    )
    private Integer progressPercentage;

    private Instant startedAt;

    private Instant completedAt;

    @Column(
            nullable = false,
            updatable = false
    )
    private Instant createdAt;

    @Column(
            nullable = false
    )
    private Instant updatedAt;

    @PrePersist
    void onCreate() {

        Instant now = Instant.now();

        if (createdAt == null) {
            createdAt = now;
        }

        if (updatedAt == null) {
            updatedAt = now;
        }

        if (startedAt == null) {
            startedAt = now;
        }

        if (completed == null) {
            completed = false;
        }

        if (progressPercentage == null) {
            progressPercentage = 10;
        }

        if (currentStage == null) {
            currentStage = LearningStage.UNDERSTAND;
        }
    }

    @PreUpdate
    void onUpdate() {
        updatedAt = Instant.now();
    }

    /**
     * Returns the stages completed before the current stage.
     *
     * Never returns null.
     *
     * Example:
     *
     * currentStage = CODE
     *
     * completed stages:
     * UNDERSTAND
     * VISUALIZE
     * RELATE
     * REMEMBER
     * BATTLE
     */
    public List<String> getCompletedStages() {

        if (currentStage == null) {
            return List.of();
        }

        return Arrays.stream(LearningStage.values())
                .filter(stage ->
                        stage.ordinal() < currentStage.ordinal()
                )
                .map(Enum::name)
                .toList();
    }
}