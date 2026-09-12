package com.bytebattle.coding.entities;


import com.bytebattle.coding.enums.CodingSubmissionStatus;
import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "coding_submissions")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CodingSubmission {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(name = "coding_challenge_id", nullable = false)
    private UUID codingChallengeId;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "source_code", columnDefinition = "TEXT")
    private String sourceCode;

    private String language;

    @Enumerated(EnumType.STRING)
    private CodingSubmissionStatus status;

    @Column(name = "execution_time_ms")
    private Integer executionTimeMs;

    @Column(name = "memory_used_bytes")
    private Long memoryUsedBytes;

    @Column(name = "test_cases_passed")
    private Integer testCasesPassed;

    @Column(name = "test_cases_total")
    private Integer testCasesTotal;

    @Column(name = "error_message", columnDefinition = "TEXT")
    private String errorMessage;

    @Column(name = "submitted_at")
    private Instant submittedAt;
}