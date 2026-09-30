package com.bytebattle.battle.entity;


import com.bytebattle.battle.enums.AttemptStatus;
import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "attempts")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Attempt {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false)
    private UUID battleSessionId;

    @Column(nullable = false)
    private UUID battleQuestionId;

    @Column(nullable = false)
    private String answer;

    @Column(nullable = false)
    private Boolean correct;

    @Column(nullable = false)
    private Integer pointsEarned;

    @Column(nullable = false)
    private Integer timeTakenSeconds;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private AttemptStatus status;

    @Column(nullable = false, updatable = false)
    private Instant attemptedAt;

    @PrePersist
    void onCreate() {
        attemptedAt = Instant.now();
    }
}
