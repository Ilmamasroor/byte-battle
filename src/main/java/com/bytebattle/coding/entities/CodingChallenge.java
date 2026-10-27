package com.bytebattle.coding.entities;


import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "coding_challenges")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CodingChallenge {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(name = "concept_id", nullable = false)
    private UUID conceptId;

    private String title;
    
    @Column(name = "test_cases", columnDefinition = "TEXT")
    private String testCases; // JSON array of {input, expectedOutput} pairs

    @Column(columnDefinition = "TEXT")
    private String description;

    private String difficulty;
    private String language;

    @Column(name = "input_description", columnDefinition = "TEXT")
    private String inputDescription;

    @Column(name = "output_description", columnDefinition = "TEXT")
    private String outputDescription;

    @Column(columnDefinition = "TEXT")
    private String constraints;

    @Column(name = "starter_code", columnDefinition = "TEXT")
    private String starterCode;

    // SECURITY: never expose this field in any learner-facing DTO — doc §19.
    @Column(name = "solution_code", columnDefinition = "TEXT")
    private String solutionCode;

    @Column(name = "time_limit_ms")
    private Integer timeLimitMs;

    @Column(name = "memory_limit_mb")
    private Integer memoryLimitMb;

    @Column(name = "created_at")
    private Instant createdAt;

    @Column(name = "updated_at")
    private Instant updatedAt;
}
