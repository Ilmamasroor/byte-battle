package com.bytebattle.learning;

import com.bytebattle.gamification.service.GamificationService;
import com.bytebattle.learning.enums.LearningStage;
import com.bytebattle.learning.service.LearningService;
import com.bytebattle.learning.service.ProgressionService;
import com.bytebattle.performance.enums.ActivityType;
import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.Mockito.*;

class ProgressionServiceTest {

    final GamificationService gamification = mock(GamificationService.class);
    final LearningService learning = mock(LearningService.class);
    final ProgressionService service = new ProgressionService(gamification, learning);
    final UUID user = UUID.randomUUID();
    final UUID concept = UUID.randomUUID();

    @Test
    void passingBattleAwardsXpAndAdvancesFromBattleStage() {
        service.onActivity(user, concept, ActivityType.BATTLE, true, false);
        verify(gamification).recordActivity(user, 50);
        verify(learning).advanceIfAt(user, concept, LearningStage.BATTLE);
    }

    @Test
    void bossBattleWinIsWorthMore() {
        service.onActivity(user, concept, ActivityType.BATTLE, true, true);
        verify(gamification).recordActivity(user, 100);
    }

    @Test
    void failedAttemptKeepsTheStreakAliveButNeverAdvancesTheStage() {
        service.onActivity(user, concept, ActivityType.CODING, false, false);
        verify(gamification).recordActivity(user, 5);
        verifyNoInteractions(learning);
    }

    @Test
    void eachActivityCompletesItsOwnStage() {
        service.onActivity(user, concept, ActivityType.CODING, true, false);
        service.onActivity(user, concept, ActivityType.DEBUGGING, true, false);
        service.onActivity(user, concept, ActivityType.INTERVIEW, true, false);
        verify(learning).advanceIfAt(user, concept, LearningStage.CODE);
        verify(learning).advanceIfAt(user, concept, LearningStage.DEBUG);
        verify(learning).advanceIfAt(user, concept, LearningStage.INTERVIEW);
    }

    @Test
    void aFailureInProgressionNeverBreaksTheGradedResult() {
        when(gamification.recordActivity(any(), anyInt())).thenThrow(new IllegalStateException("db down"));
        service.onActivity(user, concept, ActivityType.BATTLE, true, false); // must not throw
    }
}
