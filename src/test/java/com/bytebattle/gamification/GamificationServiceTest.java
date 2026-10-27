package com.bytebattle.gamification;

import com.bytebattle.gamification.dto.LearnerStatsResponse;
import com.bytebattle.gamification.entity.LearnerStats;
import com.bytebattle.gamification.repository.LearnerStatsRepository;
import com.bytebattle.gamification.service.GamificationService;
import org.junit.jupiter.api.Test;

import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class GamificationServiceTest {

    final UUID user = UUID.randomUUID();
    final LearnerStatsRepository repository = mock(LearnerStatsRepository.class);
    final Clock clock = Clock.fixed(Instant.parse("2026-10-15T10:00:00Z"), ZoneOffset.UTC);
    final GamificationService service = new GamificationService(repository, clock);

    LearnerStats stats(int xp, int streak, LocalDate last) {
        return LearnerStats.builder().userId(user).xp(xp).streakDays(streak).lastActivityDate(last).build();
    }

    void existing(LearnerStats s) {
        when(repository.findById(user)).thenReturn(Optional.of(s));
        when(repository.save(any())).thenAnswer(i -> i.getArgument(0));
    }

    @Test
    void firstActivityStartsTheStreakAndAwardsXp() {
        when(repository.findById(user)).thenReturn(Optional.empty());
        when(repository.save(any())).thenAnswer(i -> i.getArgument(0));

        LearnerStatsResponse r = service.recordActivity(user, 50);

        assertThat(r.xp()).isEqualTo(50);
        assertThat(r.streakDays()).isEqualTo(1);
        assertThat(r.lastActivityDate()).isEqualTo(LocalDate.of(2026, 10, 15));
    }

    @Test
    void consecutiveDayExtendsTheStreak() {
        existing(stats(20, 3, LocalDate.of(2026, 10, 14)));
        assertThat(service.recordActivity(user, 10).streakDays()).isEqualTo(4);
    }

    @Test
    void sameDayDoesNotInflateTheStreak() {
        existing(stats(20, 3, LocalDate.of(2026, 10, 15)));
        LearnerStatsResponse r = service.recordActivity(user, 10);
        assertThat(r.streakDays()).isEqualTo(3);
        assertThat(r.xp()).isEqualTo(30);
    }

    @Test
    void aMissedDayResetsTheStreak() {
        existing(stats(20, 7, LocalDate.of(2026, 10, 12)));
        assertThat(service.recordActivity(user, 0).streakDays()).isEqualTo(1);
    }

    @Test
    void levelRisesEveryHundredXpAndNegativeXpIsIgnored() {
        existing(stats(95, 1, LocalDate.of(2026, 10, 15)));
        LearnerStatsResponse r = service.recordActivity(user, 10);
        assertThat(r.level()).isEqualTo(2);
        assertThat(service.recordActivity(user, -500).xp()).isEqualTo(105);
    }

    @Test
    void learnerWithNoActivityGetsAZeroedProfile() {
        when(repository.findById(user)).thenReturn(Optional.empty());
        LearnerStatsResponse r = service.get(user);
        assertThat(r.xp()).isZero();
        assertThat(r.level()).isEqualTo(1);
        assertThat(r.streakDays()).isZero();
    }
}
