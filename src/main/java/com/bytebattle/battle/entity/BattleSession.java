package com.bytebattle.battle.entity;


import com.bytebattle.battle.enums.BattleSessionStatus;
import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "battle_sessions")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class BattleSession {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false)
    private UUID battleId;

    @Column(nullable = false)
    private UUID userId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private BattleSessionStatus status;

    @Column(nullable = false)
    private Integer currentQuestionNumber;

    @Column(nullable = false)
    private Integer score;

    @Column(nullable = false)
    private Integer remainingLives;

    @Column(nullable = false)
    private Instant startedAt;

    private Instant expiresAt;

    private Instant completedAt;

    @Column(nullable = false, updatable = false)
    private Instant createdAt;

    @Column(nullable = false)
    private Instant updatedAt;

    @PrePersist
    void onCreate() {
        var now = Instant.now();
        createdAt = now;
        updatedAt = now;
        if (startedAt == null) startedAt = now;
    }

    @PreUpdate
    void onUpdate() {
        updatedAt = Instant.now();
    }
}