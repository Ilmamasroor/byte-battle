package com.bytebattle.battle.entity;


import com.bytebattle.battle.enums.BattleStatus;
import com.bytebattle.battle.enums.BattleType;
import jakarta.persistence.*;
import lombok.*;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "battles")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Battle {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false)
    private UUID conceptId;

    @Column(nullable = false)
    private String title;

    private String description;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private BattleType battleType;

    @Column(nullable = false)
    private String difficulty;

    @Column(nullable = false)
    private Integer totalQuestions;

    @Column(nullable = false)
    private Integer timeLimitSeconds;

    @Column(nullable = false)
    private Integer totalLives;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private BattleStatus status;

    @Column(nullable = false, updatable = false)
    private Instant createdAt;

    @Column(nullable = false)
    private Instant updatedAt;

    @PrePersist
    void onCreate() {
        var now = Instant.now();
        createdAt = now;
        updatedAt = now;
    }

    @PreUpdate
    void onUpdate() {
        updatedAt = Instant.now();
    }
}