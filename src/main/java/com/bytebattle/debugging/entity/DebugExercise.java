package com.bytebattle.debugging.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "debug_exercises")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DebugExercise {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "concept_id", nullable = false)
    private UUID conceptId;

    @Column(nullable = false)
    private String title;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(name = "buggy_code", nullable = false, columnDefinition = "TEXT")
    private String buggyCode;

    @Column(nullable = false, length = 50)
    private String language;

    @Column(name = "test_cases_json", nullable = false, columnDefinition = "TEXT")
    private String testCasesJson;

    @Column(name = "hint_ladder_json", columnDefinition = "TEXT")
    private String hintLadderJson;

    @Column(name = "bug_category", length = 100)
    private String bugCategory;

    @Column(length = 50)
    private String difficulty;

    // SECURITY: never expose in any learner-facing DTO.
    @Column(name = "solution_code", columnDefinition = "TEXT")
    private String solutionCode;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @PrePersist
    void onCreate() {
        if (createdAt == null) {
            createdAt = Instant.now();
        }
    }
}
