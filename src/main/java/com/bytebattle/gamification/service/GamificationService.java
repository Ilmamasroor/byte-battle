package com.bytebattle.gamification.service;

import com.bytebattle.gamification.dto.LearnerStatsResponse;
import com.bytebattle.gamification.entity.LearnerStats;
import com.bytebattle.gamification.repository.LearnerStatsRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.LocalDate;
import java.util.UUID;

/**
 * XP and streaks. Only the backend calls {@link #recordActivity}, and only for verified achievements
 * (a judged coding result, a graded battle, ...): there is deliberately no public endpoint that awards XP.
 */
@Service
public class GamificationService {

    static final int XP_PER_LEVEL = 100;

    private final LearnerStatsRepository repository;
    private final Clock clock;

    public GamificationService(LearnerStatsRepository repository, Clock clock) {
        this.repository = repository;
        this.clock = clock;
    }

    /** Counts the day as active (streak) and adds {@code xp} (may be 0 for an unsuccessful attempt). */
    @Transactional
    public LearnerStatsResponse recordActivity(UUID userId, int xp) {
        LocalDate today = LocalDate.now(clock);
        LearnerStats stats = repository.findById(userId).orElseGet(() -> LearnerStats.builder()
                .userId(userId).xp(0).streakDays(0).build());

        LocalDate last = stats.getLastActivityDate();
        if (last == null || last.isBefore(today.minusDays(1))) {
            stats.setStreakDays(1);
        } else if (last.isEqual(today.minusDays(1))) {
            stats.setStreakDays(stats.getStreakDays() + 1);
        }
        // last == today: streak already counted for today
        stats.setLastActivityDate(today);
        stats.setXp(stats.getXp() + Math.max(0, xp));
        return toResponse(repository.save(stats));
    }

    @Transactional(readOnly = true)
    public LearnerStatsResponse get(UUID userId) {
        return repository.findById(userId)
                .map(this::toResponse)
                .orElseGet(() -> new LearnerStatsResponse(0, 1, 0, null));
    }

    private LearnerStatsResponse toResponse(LearnerStats s) {
        return new LearnerStatsResponse(s.getXp(), s.getXp() / XP_PER_LEVEL + 1, s.getStreakDays(), s.getLastActivityDate());
    }
}
