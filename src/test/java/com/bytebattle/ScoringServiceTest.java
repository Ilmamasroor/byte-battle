package com.bytebattle;


import com.bytebattle.battle.service.ScoringService;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class ScoringServiceTest {

    private final ScoringService scoringService = new ScoringService();

    @Test
    void incorrectAnswer_alwaysScoresZero() {
        int points = scoringService.calculatePoints(false, "HARD", 5, 60, 100);
        assertThat(points).isZero();
    }

    @Test
    void correctAnswer_easyDifficulty_noBonus_scoresBasePoints() {
        // full time used, no speed bonus, EASY multiplier = 1.0
        int points = scoringService.calculatePoints(true, "EASY", 60, 60, 10);
        assertThat(points).isEqualTo(10);
    }

    @Test
    void correctAnswer_hardDifficulty_appliesMultiplier() {
        int points = scoringService.calculatePoints(true, "HARD", 60, 60, 10);
        assertThat(points).isEqualTo(20); // 10 * 2.0 multiplier, no speed bonus
    }

    @Test
    void fasterAnswer_earnsMoreThanSlowerAnswer_sameDifficulty() {
        int slow = scoringService.calculatePoints(true, "MEDIUM", 55, 60, 10);
        int fast = scoringService.calculatePoints(true, "MEDIUM", 5, 60, 10);
        assertThat(fast).isGreaterThan(slow);
    }

    @Test
    void unknownDifficulty_fallsBackToBaselineMultiplier_neverThrows() {
        int points = scoringService.calculatePoints(true, "NONSENSE", 60, 60, 10);
        assertThat(points).isEqualTo(10); // same as EASY/default multiplier 1.0
    }

    @Test
    void speedBonus_neverExceedsCap() {
        // instant answer (timeTaken = 0) should hit the 50% cap, not exceed it
        int points = scoringService.calculatePoints(true, "EASY", 0, 60, 100);
        assertThat(points).isEqualTo(150); // 100 * 1.0 * 1.5 cap
    }
}