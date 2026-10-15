package com.bytebattle.battle;

import com.bytebattle.battle.dto.BattleResultResponse;
import com.bytebattle.battle.dto.SubmitAnswerRequest;
import com.bytebattle.battle.dto.SubmitAnswerResponse;
import com.bytebattle.battle.entity.Attempt;
import com.bytebattle.battle.entity.Battle;
import com.bytebattle.battle.entity.BattleQuestion;
import com.bytebattle.battle.entity.BattleSession;
import com.bytebattle.battle.enums.BattleSessionStatus;
import com.bytebattle.battle.enums.BattleType;
import com.bytebattle.battle.repository.AttemptRepository;
import com.bytebattle.battle.repository.BattleQuestionRepository;
import com.bytebattle.battle.repository.BattleRepository;
import com.bytebattle.battle.repository.BattleSessionRepository;
import com.bytebattle.battle.service.BattleService;
import com.bytebattle.battle.service.ScoringService;
import com.bytebattle.battle.validator.BattleStateValidator;
import com.bytebattle.learning.service.ActivityEvidenceEvent;
import com.bytebattle.learning.service.ProgressionService;
import com.bytebattle.performance.dto.CreatePerformanceRecordRequest;
import com.bytebattle.performance.enums.ActivityType;
import com.bytebattle.performance.service.PerformanceService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.context.ApplicationEventPublisher;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyBoolean;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

class BattleServiceTest {

    BattleRepository battles = mock(BattleRepository.class);
    BattleQuestionRepository questions = mock(BattleQuestionRepository.class);
    BattleSessionRepository sessions = mock(BattleSessionRepository.class);
    AttemptRepository attempts = mock(AttemptRepository.class);
    BattleStateValidator validator = mock(BattleStateValidator.class);
    ScoringService scoring = mock(ScoringService.class);
    PerformanceService performance = mock(PerformanceService.class);
    ProgressionService progression = mock(ProgressionService.class);
    ApplicationEventPublisher publisher = mock(ApplicationEventPublisher.class);
    BattleService service;

    final UUID user = UUID.randomUUID();
    final UUID concept = UUID.randomUUID();
    final UUID battleId = UUID.randomUUID();
    final UUID sessionId = UUID.randomUUID();
    Battle battle;
    BattleSession session;

    @BeforeEach
    void setUp() {
        service = new BattleService(battles, questions, sessions, attempts, validator, scoring,
                performance, progression, publisher);
        battle = Battle.builder().id(battleId).conceptId(concept).battleType(BattleType.QUIZ)
                .difficulty("EASY").totalQuestions(2).timeLimitSeconds(60).totalLives(2).build();
        session = BattleSession.builder().id(sessionId).battleId(battleId).userId(user)
                .status(BattleSessionStatus.ACTIVE).currentQuestionNumber(1).score(0).remainingLives(2).build();
        when(battles.findById(battleId)).thenReturn(Optional.of(battle));
        when(validator.requireOwnedSession(sessionId, user)).thenReturn(session);
        when(validator.requireActiveSession(session)).thenReturn(session);
        when(scoring.calculatePoints(anyBoolean(), any(), anyInt(), anyInt(), anyInt())).thenReturn(10);
    }

    private static Attempt attempt(boolean correct, int seconds) {
        return Attempt.builder().correct(correct).timeTakenSeconds(seconds).build();
    }

    private BattleQuestion question(int order, String correct) {
        return BattleQuestion.builder().id(UUID.randomUUID()).battleId(battleId).displayOrder(order)
                .correctAnswer(correct).points(10).build();
    }

    @Test
    void answerIsGradedServerSideCaseInsensitivelyAndTheLastAnswerFinishesWithEvidence() {
        BattleQuestion last = question(2, "start()");
        when(questions.findById(last.getId())).thenReturn(Optional.of(last));
        when(validator.requireQuestionInBattle(last, battleId)).thenReturn(last);
        when(questions.findByBattleIdOrderByDisplayOrderAsc(battleId)).thenReturn(List.of(question(1, "x"), last));
        when(attempts.findByBattleSessionId(sessionId)).thenReturn(List.of(attempt(true, 5), attempt(true, 8)));

        SubmitAnswerResponse r = service.submitAnswer(sessionId, user,
                new SubmitAnswerRequest(last.getId(), "  START() ", 8));

        assertThat(r.correct()).isTrue();
        assertThat(r.sessionCompleted()).isTrue();
        assertThat(session.getStatus()).isEqualTo(BattleSessionStatus.COMPLETED);

        ArgumentCaptor<CreatePerformanceRecordRequest> rec = ArgumentCaptor.forClass(CreatePerformanceRecordRequest.class);
        verify(performance).createRecord(rec.capture());
        assertThat(rec.getValue().activityType()).isEqualTo(ActivityType.BATTLE);
        assertThat(rec.getValue().success()).isTrue();
        assertThat(rec.getValue().score()).isEqualTo(100);
        assertThat(rec.getValue().timeSpentSeconds()).isEqualTo(13);
        verify(progression).onActivity(user, concept, ActivityType.BATTLE, true, false);
        verify(publisher).publishEvent(any(ActivityEvidenceEvent.class));
    }

    @Test
    void losingTheLastLifeEndsTheSessionAsAnUnsuccessfulBattle() {
        session.setRemainingLives(1);
        BattleQuestion first = question(1, "right");
        when(questions.findById(first.getId())).thenReturn(Optional.of(first));
        when(validator.requireQuestionInBattle(first, battleId)).thenReturn(first);
        when(questions.findByBattleIdOrderByDisplayOrderAsc(battleId)).thenReturn(List.of(first, question(2, "x")));
        when(attempts.findByBattleSessionId(sessionId)).thenReturn(List.of(attempt(false, 4)));

        SubmitAnswerResponse r = service.submitAnswer(sessionId, user, new SubmitAnswerRequest(first.getId(), "wrong", 4));

        assertThat(r.correct()).isFalse();
        assertThat(r.sessionCompleted()).isTrue();
        verify(progression).onActivity(user, concept, ActivityType.BATTLE, false, false);
    }

    @Test
    void completingEarlyEndsTheSessionAndAbandoningIsNeverAWin() {
        when(attempts.findByBattleSessionId(sessionId)).thenReturn(List.of(attempt(true, 3)));

        BattleResultResponse r = service.completeSession(sessionId, user);

        assertThat(session.getStatus()).isEqualTo(BattleSessionStatus.COMPLETED);
        assertThat(r.won()).isFalse(); // lives left, but only 1 of 2 questions answered
        verify(progression).onActivity(user, concept, ActivityType.BATTLE, false, false);
    }

    @Test
    void completingAnAlreadyFinishedSessionDoesNotRecordEvidenceTwice() {
        session.setStatus(BattleSessionStatus.COMPLETED);
        when(attempts.findByBattleSessionId(sessionId)).thenReturn(List.of(attempt(true, 3), attempt(true, 3)));

        BattleResultResponse r = service.completeSession(sessionId, user);

        assertThat(r.won()).isTrue();
        verifyNoInteractions(performance, progression, publisher);
    }

    @Test
    void bossBattleWinIsFlaggedForTheBiggerReward() {
        battle.setBattleType(BattleType.BOSS_BATTLE);
        session.setStatus(BattleSessionStatus.ACTIVE);
        when(attempts.findByBattleSessionId(sessionId)).thenReturn(List.of(attempt(true, 2), attempt(true, 2)));

        service.completeSession(sessionId, user);

        verify(progression).onActivity(eq(user), eq(concept), eq(ActivityType.BATTLE), eq(true), eq(true));
    }
}
