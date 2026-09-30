package com.bytebattle.interview.entity;

import com.bytebattle.interview.enums.InterviewStatus;
import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(
        name = "interview_sessions",
        indexes = {
                @Index(
                        name = "idx_interview_user_created",
                        columnList = "user_id, created_at"
                ),
                @Index(
                        name = "idx_interview_user_status",
                        columnList = "user_id, status"
                )
        }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class InterviewSession {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "user_id", nullable = false)
    private String userId;

    @Column(name = "concept_id", nullable = false)
    private UUID conceptId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private InterviewStatus status;

    @Column(nullable = false, length = 30)
    private String difficulty;

    @Column(name = "started_at", nullable = false)
    private Instant startedAt;

    @Column(name = "completed_at")
    private Instant completedAt;

    @Column
    private Integer score;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @PrePersist
    void onCreate() {
        Instant now = Instant.now();

        createdAt = now;
        updatedAt = now;

        if (startedAt == null) {
            startedAt = now;
        }

        if (status == null) {
            status = InterviewStatus.IN_PROGRESS;
        }
    }

    @PreUpdate
    void onUpdate() {
        updatedAt = Instant.now();
    }
}