package com.bytebattle.debugging;

import com.bytebattle.coding.dto.ExecutionResult;
import com.bytebattle.coding.enums.CodingSubmissionStatus;
import com.bytebattle.coding.execution.CodeExecutor;
import com.bytebattle.debugging.dto.DebugExerciseDtos.*;
import com.bytebattle.debugging.entity.DebugAttempt;
import com.bytebattle.debugging.entity.DebugExercise;
import com.bytebattle.debugging.enums.ErrorCategory;
import com.bytebattle.debugging.repository.DebugAttemptRepository;
import com.bytebattle.debugging.repository.DebugExerciseRepository;
import com.bytebattle.debugging.service.DebugExerciseService;
import com.bytebattle.performance.dto.CreatePerformanceRecordRequest;
import com.bytebattle.performance.enums.ActivityType;
import com.bytebattle.performance.service.PerformanceService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class DebugExerciseServiceTest {

    private static final String CASES = "[{\"input\":\"3\",\"expectedOutput\":\"9\"},"
            + "{\"input\":\"HIDDEN_IN\",\"expectedOutput\":\"HIDDEN_OUT\",\"hidden\":true}]";

    @Mock DebugExerciseRepository exercises;
    @Mock DebugAttemptRepository attempts;
    @Mock CodeExecutor executor;
    @Mock PerformanceService performance;
    @Mock com.bytebattle.learning.service.ProgressionService progression;
    @Mock org.springframework.context.ApplicationEventPublisher publisher;

    DebugExerciseService service;
    UUID userId = UUID.randomUUID();
    UUID exerciseId = UUID.randomUUID();
    UUID conceptId = UUID.randomUUID();
    DebugExercise exercise;
    List<DebugAttempt> stored = new ArrayList<>();

    @BeforeEach
    void setUp() {
        service = new DebugExerciseService(exercises, attempts, executor, performance, new ObjectMapper(), progression, publisher);
        exercise = DebugExercise.builder().id(exerciseId).conceptId(conceptId).title("Bug").language("JAVA")
                .buggyCode("buggy").solutionCode("SECRET_SOLUTION").testCasesJson(CASES)
                .hintLadderJson("[\"one\",\"two\",{\"text\":\"three\"}]").bugCategory("RACE_CONDITION").difficulty("EASY").build();
        lenient().when(exercises.findById(exerciseId)).thenReturn(Optional.of(exercise));
        lenient().when(attempts.save(any(DebugAttempt.class))).thenAnswer(inv -> {
            DebugAttempt a = inv.getArgument(0);
            if (a.getId() == null) {
                a.setId(UUID.randomUUID());
                a.setCreatedAt(Instant.now());
                stored.add(0, a);
            }
            return a;
        });
        lenient().when(attempts.findTop10ByUserIdAndExerciseIdOrderByCreatedAtDesc(userId, exerciseId))
                .thenAnswer(inv -> new ArrayList<>(stored));
        lenient().when(attempts.findTopByUserIdAndExerciseIdOrderByCreatedAtDesc(userId, exerciseId))
                .thenAnswer(inv -> stored.stream().findFirst());
        lenient().when(attempts.countByUserIdAndExerciseId(userId, exerciseId)).thenAnswer(inv -> (long) stored.size());
    }

    private static ExecutionResult failing() {
        return new ExecutionResult(false, 1, 2, 10, 1L, "Wrong answer on 1 of 2 test cases", List.of(
                new ExecutionResult.TestCaseOutcome(1, true, "9", "9", "3", false, "ACCEPTED", 5, 1),
                new ExecutionResult.TestCaseOutcome(2, false, "HIDDEN_BAD", "HIDDEN_OUT", "HIDDEN_IN", true, "WRONG_ANSWER", 5, 1)),
                CodingSubmissionStatus.FAILED);
    }

    private static ExecutionResult passing() {
        return new ExecutionResult(true, 2, 2, 10, 1L, null, List.of(
                new ExecutionResult.TestCaseOutcome(1, true, "9", "9", "3", false, "ACCEPTED", 5, 1),
                new ExecutionResult.TestCaseOutcome(2, true, "HIDDEN_OUT", "HIDDEN_OUT", "HIDDEN_IN", true, "ACCEPTED", 5, 1)),
                CodingSubmissionStatus.PASSED);
    }

    @Test
    void detailShowsBuggyCodeAndVisibleTestsOnly() throws Exception {
        ExerciseDetail detail = service.get(exerciseId);

        assertThat(detail.buggyCode()).isEqualTo("buggy");
        assertThat(detail.sampleTests()).hasSize(1);
        assertThat(detail.totalTests()).isEqualTo(2);
        assertThat(detail.hiddenTests()).isEqualTo(1);
        assertThat(detail.hintCount()).isEqualTo(3);
        assertThat(new ObjectMapper().writeValueAsString(detail)).doesNotContain("SECRET_SOLUTION", "HIDDEN_IN", "HIDDEN_OUT");
    }

    @Test
    void failedAttemptsEscalateToDiagnoseThenPersistentWeakness() throws Exception {
        when(executor.execute(any())).thenReturn(failing());
        AttemptRequest request = new AttemptRequest("code", 30);

        AttemptResponse first = service.attempt(userId, exerciseId, request);
        assertThat(first.nextAction()).isEqualTo("RETRY");
        assertThat(first.persistentWeakness()).isFalse();
        assertThat(first.errorCategory()).isEqualTo(ErrorCategory.LOGIC_ERROR);
        assertThat(first.consecutiveFailures()).isEqualTo(1);

        AttemptResponse second = service.attempt(userId, exerciseId, request);
        assertThat(second.nextAction()).isEqualTo("DIAGNOSE");
        assertThat(second.persistentWeakness()).isFalse();

        AttemptResponse third = service.attempt(userId, exerciseId, request);
        assertThat(third.nextAction()).isEqualTo("DIAGNOSE");
        assertThat(third.persistentWeakness()).isTrue();
        assertThat(third.consecutiveFailures()).isEqualTo(3);

        assertThat(third.testCaseResults().get(1).hidden()).isTrue();
        assertThat(new ObjectMapper().writeValueAsString(third)).doesNotContain("HIDDEN_IN", "HIDDEN_OUT", "HIDDEN_BAD");

        ArgumentCaptor<CreatePerformanceRecordRequest> record = ArgumentCaptor.forClass(CreatePerformanceRecordRequest.class);
        verify(performance, times(3)).createRecord(record.capture());
        CreatePerformanceRecordRequest last = record.getAllValues().get(2);
        assertThat(last.activityType()).isEqualTo(ActivityType.DEBUGGING);
        assertThat(last.success()).isFalse();
        assertThat(last.attemptCount()).isEqualTo(3);
        assertThat(last.accuracy()).isEqualTo(0.5);
        assertThat(last.timeSpentSeconds()).isEqualTo(30);
        assertThat(last.userId()).isEqualTo(userId);
        assertThat(last.conceptId()).isEqualTo(conceptId);
    }

    @Test
    void successResetsTheFailureStreak() {
        when(executor.execute(any())).thenReturn(failing(), failing(), passing(), failing());
        AttemptRequest request = new AttemptRequest("code", null);
        service.attempt(userId, exerciseId, request);
        service.attempt(userId, exerciseId, request);

        AttemptResponse passed = service.attempt(userId, exerciseId, request);
        assertThat(passed.passed()).isTrue();
        assertThat(passed.nextAction()).isEqualTo("CONTINUE");
        assertThat(passed.errorCategory()).isNull();
        assertThat(passed.consecutiveFailures()).isZero();

        AttemptResponse after = service.attempt(userId, exerciseId, request);
        assertThat(after.consecutiveFailures()).isEqualTo(1);
        assertThat(after.nextAction()).isEqualTo("RETRY");
    }

    @Test
    void timeoutIsCategorizedAsTimeout() {
        when(executor.execute(any())).thenReturn(new ExecutionResult(false, 0, 2, 5000, null, "Time limit exceeded",
                List.of(), CodingSubmissionStatus.TIMEOUT));

        AttemptResponse r = service.attempt(userId, exerciseId, new AttemptRequest("code", null));

        assertThat(r.errorCategory()).isEqualTo(ErrorCategory.TIMEOUT);
    }

    @Test
    void unavailableExecutionIs503AndRecordsNothing() {
        when(executor.execute(any())).thenReturn(ExecutionResult.unavailable("down"));

        assertThatThrownBy(() -> service.attempt(userId, exerciseId, new AttemptRequest("code", null)))
                .isInstanceOfSatisfying(ResponseStatusException.class,
                        e -> assertThat(e.getStatusCode()).isEqualTo(HttpStatus.SERVICE_UNAVAILABLE));
        verify(attempts, never()).save(any());
        verifyNoInteractions(performance);
    }

    @Test
    void hintsAreProgressiveAndCountedOnTheLatestAttempt() {
        when(executor.execute(any())).thenReturn(failing());
        service.attempt(userId, exerciseId, new AttemptRequest("code", null));

        HintResponse one = service.hint(userId, exerciseId, 1);
        assertThat(one.hint()).isEqualTo("one");
        assertThat(one.totalLevels()).isEqualTo(3);
        assertThat(one.hintsUsed()).isEqualTo(1);
        assertThat(one.counted()).isTrue();

        HintResponse three = service.hint(userId, exerciseId, 3);
        assertThat(three.hint()).isEqualTo("three");
        assertThat(three.hintsUsed()).isEqualTo(3);

        // asking for an earlier hint never lowers the count
        assertThat(service.hint(userId, exerciseId, 2).hintsUsed()).isEqualTo(3);
        assertThatThrownBy(() -> service.hint(userId, exerciseId, 4)).isInstanceOf(ResponseStatusException.class);
        assertThatThrownBy(() -> service.hint(userId, exerciseId, 0)).isInstanceOf(ResponseStatusException.class);
    }

    @Test
    void hintBeforeAnyAttemptIsReturnedButNotCounted() {
        HintResponse hint = service.hint(userId, exerciseId, 1);

        assertThat(hint.hint()).isEqualTo("one");
        assertThat(hint.counted()).isFalse();
        verify(attempts, never()).save(any());
    }

    @Test
    void adminCreateRejectsInvalidTestCases() {
        assertThatThrownBy(() -> service.adminCreate(new AdminExerciseRequest(conceptId, "t", null, "b", "JAVA",
                "[]", null, null, null, "s"))).isInstanceOf(IllegalArgumentException.class);
        assertThatThrownBy(() -> service.adminCreate(new AdminExerciseRequest(conceptId, "t", null, "b", "JAVA",
                CASES, "{\"not\":\"array\"}", null, null, "s"))).isInstanceOf(IllegalArgumentException.class);
    }
}
