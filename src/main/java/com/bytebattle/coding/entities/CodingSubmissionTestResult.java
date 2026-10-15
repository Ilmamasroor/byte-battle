package com.bytebattle.coding.entities;

import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;
import java.util.UUID;

/** Per-test-case outcome of a coding submission. stdoutSnippet is stored for visible (sample) cases only. */
@Entity
@Table(name = "coding_submission_test_results")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CodingSubmissionTestResult {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "submission_id", nullable = false)
    private UUID submissionId;

    @Column(name = "case_number", nullable = false)
    private Integer caseNumber;

    @Column(nullable = false)
    private Boolean hidden;

    @Column(nullable = false)
    private Boolean passed;

    @Column(nullable = false, length = 50)
    private String status;

    @Column(name = "time_ms")
    private Integer timeMs;

    @Column(name = "memory_kb")
    private Integer memoryKb;

    @Column(name = "stdout_snippet", columnDefinition = "TEXT")
    private String stdoutSnippet;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @PrePersist
    void onCreate() {
        if (createdAt == null) {
            createdAt = Instant.now();
        }
    }
}
