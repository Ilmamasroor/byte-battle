package com.bytebattle.battle.service;

import org.springframework.stereotype.Service;

@Service
public class ScoringService {

    private static final double SPEED_BONUS_CAP = 0.5; // max 50% bonus for speed

    public int calculatePoints(boolean correct, String difficulty, int timeTakenSeconds,
                                int timeLimitSeconds, int questionPoints) {

        if (!correct) {
            return 0;
        }

        double difficultyMultiplier = difficultyMultiplier(difficulty);
        double speedBonus = speedBonus(timeTakenSeconds, timeLimitSeconds);

        double rawPoints = questionPoints * difficultyMultiplier * (1 + speedBonus);
        return (int) Math.floor(rawPoints);
    }

    private double difficultyMultiplier(String difficulty) {
        return switch (difficulty.toUpperCase()) {
            case "EASY" -> 1.0;
            case "MEDIUM" -> 1.5;
            case "HARD" -> 2.0;
            case "EXPERT" -> 3.0;
            default -> 1.0;
        };
    }

    private double speedBonus(int timeTakenSeconds, int timeLimitSeconds) {
        double remainingFraction = Math.max(0.0,
                (double) (timeLimitSeconds - timeTakenSeconds) / timeLimitSeconds);
        return Math.min(SPEED_BONUS_CAP, remainingFraction * SPEED_BONUS_CAP);
    }
}