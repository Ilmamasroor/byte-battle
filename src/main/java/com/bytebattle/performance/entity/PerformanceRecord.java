package com.bytebattle.performance.entity;

import com.bytebattle.performance.enums.ActivityType;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(
        name = "performance_records",

        indexes = {

                /**
                 * User + concept history.
                 */
                @Index(
                        name = "idx_perf_user_concept_created",
                        columnList = "user_id, concept_id, created_at"
                ),

                /**
                 * User performance history.
                 */
                @Index(
                        name = "idx_perf_user_created",
                        columnList = "user_id, created_at"
                ),

                /**
                 * Global chronological queries.
                 */
                @Index(
                        name = "idx_perf_created",
                        columnList = "created_at"
                )
        },

        /**
         * One performance record per source activity
         * for the same user and activity type.
         *
         * NULL source_id values are allowed to occur
         * multiple times.
         */
        uniqueConstraints = @UniqueConstraint(
                name = "uk_perf_source",
                columnNames = {
                        "user_id",
                        "activity_type",
                        "source_id"
                }
        )
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PerformanceRecord {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    /**
     * Owner of this evidence record.
     *
     * Must be assigned by backend logic, not trusted
     * from a client-controlled userId.
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
            name = "activity_type",
            nullable = false
    )
    private ActivityType activityType;

    @Column(nullable = false)
    private Integer score;

    /**
     * Value between 0.0 and 1.0.
     */
    @Column(nullable = false)
    private Double accuracy;

    @Column(
            name = "time_spent_seconds",
            nullable = false
    )
    private Integer timeSpentSeconds;

    @Column(
            name = "attempt_count",
            nullable = false
    )
    private Integer attemptCount;

    @Column(nullable = false)
    private Boolean success;

    /**
     * Persisted number of hints used.
     */
    @Column(
            name = "hints_used",
            nullable = false
    )
    private Integer hintsUsed;

    /**
     * Coding evidence only.
     */
    @Column(name = "test_cases_passed")
    private Integer testCasesPassed;

    /**
     * Coding evidence only.
     */
    @Column(name = "test_cases_total")
    private Integer testCasesTotal;

    /**
     * Battle session / code submission that generated
     * this performance evidence.
     *
     * Used as an idempotency key together with userId
     * and activityType.
     */
    @Column(name = "source_id")
    private UUID sourceId;

    @Column(
            name = "created_at",
            nullable = false,
            updatable = false
    )
    private Instant createdAt;

    @PrePersist
    void onCreate() {

        if (createdAt == null) {
            createdAt = Instant.now();
        }

        if (hintsUsed == null) {
            hintsUsed = 0;
        }
    }

    /**
     * Increment the persisted hint count.
     */
    public void incrementHintsUsed() {

        this.hintsUsed =
                (hintsUsed == null ? 0 : hintsUsed) + 1;
    }
}