package com.bytebattle.coding;

import com.bytebattle.coding.dto.*;
import com.bytebattle.coding.entities.CodingChallenge;
import com.bytebattle.coding.entities.CodingSubmission;
import com.bytebattle.coding.entities.CodingSubmissionTestResult;
import com.bytebattle.coding.enums.CodingSubmissionStatus;
import com.bytebattle.coding.execution.CodeExecutor;
import com.bytebattle.coding.repository.CodingChallengeRepository;
import com.bytebattle.coding.repository.CodingSubmissionRepository;
import com.bytebattle.coding.service.CodingService;
import com.bytebattle.coding.service.CodingSubmissionCompletedEvent;
import com.bytebattle.coding.service.CodingSubmissionStore;
import com.bytebattle.performance.service.PerformanceService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class CodingServiceTest {

    private static final String CASES = "[{\"input\":\"1\",\"expectedOutput\":\"VISIBLE_EXPECTED\"},"
            + "{\"input\":\"HIDDEN_INPUT\",\"expectedOutput\":\"HIDDEN_EXPECTED\",\"hidden\":true}]";

    @Mock CodingChallengeRepository challengeRepository;
    @Mock CodingSubmissionRepository submissionRepository;
    @Mock CodeExecutor executor;
    @Mock PerformanceService performanceService;
    @Mock CodingSubmissionStore store;
    @Mock ApplicationEventPublisher publisher;
    @Mock com.bytebattle.learning.service.ProgressionService progression;

    CodingService service;
    UUID challengeId = UUID.randomUUID();
    UUID userId = UUID.randomUUID();
    UUID conceptId = UUID.randomUUID();
    CodingChallenge challenge;

    @BeforeEach
    void setUp() {
        service = new CodingService(challengeRepository, submissionRepository, executor, performanceService, store, publisher, progression);
        challenge = CodingChallenge.builder().id(challengeId).conceptId(conceptId).title("T").difficulty("EASY")
                .language("JAVA").starterCode("s").solutionCode("SECRET_SOLUTION").testCases(CASES).build();
    }

    private static ExecutionResult.TestCaseOutcome outcome(int n, boolean passed, boolean hidden, String actual) {
        return new ExecutionResult.TestCaseOutcome(n, passed, actual, hidden ? "HIDDEN_EXPECTED" : "VISIBLE_EXPECTED",
                hidden ? "HIDDEN_INPUT" : "1", hidden, passed ? "ACCEPTED" : "WRONG_ANSWER", 12, 1000);
    }

    @Test
    void challengeResponseExposesOnlyVisibleSamplesAndNeverSolution() throws Exception {
        when(challengeRepository.findById(challengeId)).thenReturn(Optional.of(challenge));

        CodingChallengeResponse response = service.getChallenge(challengeId);

        assertThat(response.sampleTestCases()).hasSize(1);
        assertThat(response.sampleTestCases().get(0).input()).isEqualTo("1");
        assertThat(response.sampleTestCases().get(0).expectedOutput()).isEqualTo("VISIBLE_EXPECTED");
        assertThat(response.totalTestCases()).isEqualTo(2);
        assertThat(response.hiddenTestCases()).isEqualTo(1);
        String json = new ObjectMapper().writeValueAsString(response);
        assertThat(json).doesNotContain("SECRET_SOLUTION", "HIDDEN_INPUT", "HIDDEN_EXPECTED");
    }

    @Test
    void submissionResponseNeverLeaksHiddenCaseData() throws Exception {
        when(challengeRepository.findById(challengeId)).thenReturn(Optional.of(challenge));
        when(store.createPending(any(), any(), any(), any())).thenReturn(UUID.randomUUID());
        ExecutionResult result = new ExecutionResult(false, 1, 2, 24, 2048L, "Wrong answer on 1 of 2 test cases",
                List.of(outcome(1, true, false, "VISIBLE_EXPECTED"), outcome(2, false, true, "HIDDEN_ACTUAL")),
                CodingSubmissionStatus.FAILED);
        when(executor.execute(any())).thenReturn(result);

        CodeSubmissionResponse response = service.submitCode(challengeId, userId, new CodeSubmissionRequest("code", "java"));

        assertThat(response.status()).isEqualTo(CodingSubmissionStatus.FAILED);
        assertThat(response.aiFeedback()).isNull();
        TestCaseResultResponse visible = response.testCaseResults().get(0);
        assertThat(visible.input()).isEqualTo("1");
        assertThat(visible.expectedOutput()).isEqualTo("VISIBLE_EXPECTED");
        assertThat(visible.actualOutput()).isEqualTo("VISIBLE_EXPECTED");
        TestCaseResultResponse hidden = response.testCaseResults().get(1);
        assertThat(hidden.hidden()).isTrue();
        assertThat(hidden.passed()).isFalse();
        assertThat(hidden.input()).isNull();
        assertThat(hidden.expectedOutput()).isNull();
        assertThat(hidden.actualOutput()).isNull();
        String json = new ObjectMapper().writeValueAsString(response);
        assertThat(json).doesNotContain("HIDDEN_INPUT", "HIDDEN_EXPECTED", "HIDDEN_ACTUAL");
        verify(store).complete(any(), eq(result));
        verify(performanceService).createRecord(any());
        ArgumentCaptor<CodingSubmissionCompletedEvent> event = ArgumentCaptor.forClass(CodingSubmissionCompletedEvent.class);
        verify(publisher).publishEvent(event.capture());
        assertThat(event.getValue().conceptId()).isEqualTo(conceptId);
    }

    @Test
    void unavailableExecutionIs503AndPersistsNothingAsEvidence() {
        when(challengeRepository.findById(challengeId)).thenReturn(Optional.of(challenge));
        UUID pending = UUID.randomUUID();
        when(store.createPending(any(), any(), any(), any())).thenReturn(pending);
        when(executor.execute(any())).thenReturn(ExecutionResult.unavailable("down"));

        assertThatThrownBy(() -> service.submitCode(challengeId, userId, new CodeSubmissionRequest("code", "JAVA")))
                .isInstanceOfSatisfying(ResponseStatusException.class,
                        e -> assertThat(e.getStatusCode()).isEqualTo(HttpStatus.SERVICE_UNAVAILABLE));

        verify(store).discard(pending);
        verify(store, never()).complete(any(), any());
        verifyNoInteractions(performanceService, publisher);
    }

    @Test
    void unexpectedExecutorFailureIsAlso503NotA500() {
        when(challengeRepository.findById(challengeId)).thenReturn(Optional.of(challenge));
        when(store.createPending(any(), any(), any(), any())).thenReturn(UUID.randomUUID());
        when(executor.execute(any())).thenThrow(new IllegalStateException("boom"));

        assertThatThrownBy(() -> service.submitCode(challengeId, userId, new CodeSubmissionRequest("code", "JAVA")))
                .isInstanceOfSatisfying(ResponseStatusException.class,
                        e -> assertThat(e.getStatusCode()).isEqualTo(HttpStatus.SERVICE_UNAVAILABLE));
    }

    @Test
    void malformedChallengeDiscardsPendingAndRethrows() {
        when(challengeRepository.findById(challengeId)).thenReturn(Optional.of(challenge));
        UUID pending = UUID.randomUUID();
        when(store.createPending(any(), any(), any(), any())).thenReturn(pending);
        when(executor.execute(any())).thenThrow(new IllegalArgumentException("no test cases"));

        assertThatThrownBy(() -> service.submitCode(challengeId, userId, new CodeSubmissionRequest("code", "JAVA")))
                .isInstanceOf(IllegalArgumentException.class);
        verify(store).discard(pending);
    }

    @Test
    void getSubmissionReturnsPersistedPerCaseResultsHidingHiddenOnes() throws Exception {
        UUID submissionId = UUID.randomUUID();
        when(submissionRepository.findByIdAndUserId(submissionId, userId)).thenReturn(Optional.of(
                CodingSubmission.builder().id(submissionId).codingChallengeId(challengeId).userId(userId)
                        .status(CodingSubmissionStatus.FAILED).testCasesPassed(1).testCasesTotal(2).build()));
        when(challengeRepository.findById(challengeId)).thenReturn(Optional.of(challenge));
        when(store.results(submissionId)).thenReturn(List.of(
                CodingSubmissionTestResult.builder().caseNumber(1).hidden(false).passed(true).status("ACCEPTED")
                        .timeMs(5).stdoutSnippet("VISIBLE_EXPECTED").build(),
                CodingSubmissionTestResult.builder().caseNumber(2).hidden(true).passed(false).status("WRONG_ANSWER")
                        .timeMs(7).build()));

        CodeSubmissionResponse response = service.getSubmission(submissionId, userId);

        assertThat(response.testCaseResults()).hasSize(2);
        assertThat(response.testCaseResults().get(0).input()).isEqualTo("1");
        assertThat(response.testCaseResults().get(0).actualOutput()).isEqualTo("VISIBLE_EXPECTED");
        assertThat(response.testCaseResults().get(1).hidden()).isTrue();
        assertThat(new ObjectMapper().writeValueAsString(response)).doesNotContain("HIDDEN_INPUT", "HIDDEN_EXPECTED");
    }

    @Test
    void wrongLanguageIsRejectedBeforeAnyPersistence() {
        when(challengeRepository.findById(challengeId)).thenReturn(Optional.of(challenge));

        assertThatThrownBy(() -> service.submitCode(challengeId, userId, new CodeSubmissionRequest("code", "PYTHON")))
                .isInstanceOf(ResponseStatusException.class);
        verifyNoInteractions(store, executor);
    }
}
