package com.bytebattle.coding;

import com.bytebattle.ai.dto.feature.CodingFeedbackResponse;
import com.bytebattle.ai.service.AiFeatureService;
import com.bytebattle.ai.service.PersonalizationAiService;
import com.bytebattle.coding.dto.ExecutionResult;
import com.bytebattle.coding.enums.CodingSubmissionStatus;
import com.bytebattle.coding.service.CodingFollowUpListener;
import com.bytebattle.coding.service.CodingSubmissionCompletedEvent;
import com.bytebattle.coding.service.CodingSubmissionStore;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.core.task.SyncTaskExecutor;
import org.springframework.core.task.TaskExecutor;

import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.Executors;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class CodingFollowUpListenerTest {

    @Mock PersonalizationAiService personalization;
    @Mock AiFeatureService aiFeatureService;
    @Mock CodingSubmissionStore store;

    UUID submissionId = UUID.randomUUID();
    CodingSubmissionCompletedEvent event;

    @BeforeEach
    void setUp() {
        ExecutionResult result = new ExecutionResult(true, 1, 1, 1, 1L, null, List.of(), CodingSubmissionStatus.PASSED);
        event = new CodingSubmissionCompletedEvent(submissionId, UUID.randomUUID(), UUID.randomUUID(), UUID.randomUUID(),
                "title", "EASY", "JAVA", "class Main {}", result);
    }

    private CodingFollowUpListener listener(long timeoutMs) {
        TaskExecutor pool = new org.springframework.core.task.support.TaskExecutorAdapter(Executors.newCachedThreadPool());
        return new CodingFollowUpListener(personalization, aiFeatureService, store, pool, timeoutMs);
    }

    @Test
    void storesFeedbackAfterPersonalization() {
        when(aiFeatureService.generateCodingFeedback(any(), any())).thenReturn(new CodingFeedbackResponse("nice", false));

        listener(2000).onSubmissionCompleted(event);

        verify(personalization).processCodingAttempt(eq(event.userId()), eq(event.conceptId()), eq(event.result()));
        verify(store).saveAiFeedback(submissionId, "nice");
    }

    @Test
    void personalizationFailureNeverPropagatesAndFeedbackStillRuns() {
        doThrow(new IllegalStateException("ai down")).when(personalization).processCodingAttempt(any(), any(), any());
        when(aiFeatureService.generateCodingFeedback(any(), any())).thenReturn(new CodingFeedbackResponse("ok", false));

        assertThatCode(() -> listener(2000).onSubmissionCompleted(event)).doesNotThrowAnyException();

        verify(store).saveAiFeedback(submissionId, "ok");
    }

    @Test
    void slowFeedbackIsAbandonedAfterTheTimeout() {
        when(aiFeatureService.generateCodingFeedback(any(), any())).thenAnswer(inv -> {
            Thread.sleep(3000);
            return new CodingFeedbackResponse("late", false);
        });

        long start = System.nanoTime();
        assertThatCode(() -> listener(100).onSubmissionCompleted(event)).doesNotThrowAnyException();
        long elapsedMs = (System.nanoTime() - start) / 1_000_000;

        verify(store, never()).saveAiFeedback(any(), any());
        org.assertj.core.api.Assertions.assertThat(elapsedMs).isLessThan(2000);
    }

    @Test
    void feedbackFailureIsSwallowed() {
        when(aiFeatureService.generateCodingFeedback(any(), any())).thenThrow(new IllegalStateException("x"));

        assertThatCode(() -> listener(2000).onSubmissionCompleted(event)).doesNotThrowAnyException();
        verify(store, never()).saveAiFeedback(any(), any());
    }
}
