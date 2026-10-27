package com.bytebattle.gamification.dto;

import java.time.LocalDate;

public record LearnerStatsResponse(int xp, int level, int streakDays, LocalDate lastActivityDate) {
}
