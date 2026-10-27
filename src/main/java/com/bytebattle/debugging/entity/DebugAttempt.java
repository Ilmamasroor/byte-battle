package com.bytebattle.debugging.entity;

import com.bytebattle.debugging.enums.ErrorCategory;
import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "debug_attempts")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DebugAttempt {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "exercise_id", nullable = false)
    private UUID exerciseId;

    @Column(name = "submitted_code", nullable = false, columnDefinition = "TEXT")
    private String submittedCode;

    @Column(nullable = false, length = 50)
    private String status;

    @Column(name = "tests_passed", nullable = false)
    private Integer testsPassed;

    @Column(name = "tests_total", nullable = false)
    private Integer testsTotal;

    @Enumerated(EnumType.STRING)
    @Column(name = "error_category", length = 50)
    private ErrorCategory errorCategory;

    @Column(name = "hints_used", nullable = false)
    private Integer hintsUsed;

    @Column(name = "created_at", nullable = false, updatable = false)
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
}
