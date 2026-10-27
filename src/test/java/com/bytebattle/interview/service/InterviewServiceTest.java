package com.bytebattle.interview.service;

import com.bytebattle.ai.dto.feature.AiInterviewEvaluateResponse;
import com.bytebattle.ai.dto.feature.AiInterviewQuestionResponse;
import com.bytebattle.ai.service.AiFeatureService;
import com.bytebattle.interview.dto.InterviewMessageResponse;
import com.bytebattle.interview.dto.InterviewResultResponse;
import com.bytebattle.interview.dto.SendInterviewMessageRequest;
import com.bytebattle.interview.entity.InterviewMessage;
import com.bytebattle.interview.entity.InterviewSession;
import com.bytebattle.interview.enums.InterviewMessageRole;
import com.bytebattle.interview.enums.InterviewStatus;
import com.bytebattle.interview.repository.InterviewMessageRepository;
import com.bytebattle.interview.repository.InterviewSessionRepository;
import com.bytebattle.learning.service.ActivityEvidenceEvent;
import com.bytebattle.learning.service.ProgressionService;
import com.bytebattle.performance.dto.CreatePerformanceRecordRequest;
import com.bytebattle.performance.enums.ActivityType;
import com.bytebattle.performance.service.PerformanceService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.context.ApplicationEventPublisher;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

class InterviewServiceTest {

    InterviewSessionRepository sessions = mock(InterviewSessionRepository.class);
    InterviewMessageRepository messages = mock(InterviewMessageRepository.class);
    AiFeatureService ai = mock(AiFeatureService.class);
    PerformanceService performance = mock(PerformanceService.class);
    ProgressionService progression = mock(ProgressionService.class);
    ApplicationEventPublisher publisher = mock(ApplicationEventPublisher.class);
    InterviewService service;

    final UUID user = UUID.randomUUID();
    final UUID concept = UUID.randomUUID();
    final UUID sessionId = UUID.randomUUID();
    InterviewSession session;

    @BeforeEach
    void setUp() {
        service = new InterviewService(sessions, messages, ai, performance, progression, publisher);
        session = InterviewSession.builder().id(sessionId).userId(user).conceptId(concept)
                .status(InterviewStatus.IN_PROGRESS).difficulty("MEDIUM").startedAt(Instant.now().minusSeconds(120)).build();
        when(sessions.findByIdAndUserId(sessionId, user)).thenReturn(Optional.of(session));
        when(messages.save(any())).thenAnswer(i -> i.getArgument(0));
    }

    private static InterviewMessage msg(InterviewMessageRole role, int seq, String text, Integer score) {
        return InterviewMessage.builder().role(role).sequenceNumber(seq).content(text).score(score).build();
    }

    private static AiInterviewEvaluateResponse rubric(double v) {
        return new AiInterviewEvaluateResponse(v, v, v, v, v, "feedback");
    }

    @Test
    void scoreIsTheMeanOfTheFiveRubricDimensionsAsPercent() {
        assertThat(InterviewService.scoreOf(new AiInterviewEvaluateResponse(1.0, 0.5, 0.5, 1.0, 0.0, "f"))).isEqualTo(60);
        assertThat(InterviewService.scoreOf(rubric(1.0))).isEqualTo(100);
        assertThat(InterviewService.scoreOf(rubric(7.0))).isEqualTo(100); // out-of-range AI values are clamped
        assertThat(InterviewService.scoreOf(null)).isNull();
    }

    @Test
    void answerIsGradedAndTheReplyCarriesTheFeedbackAndTheNextAiQuestion() {
        when(messages.findByInterviewSessionIdOrderBySequenceNumberAsc(sessionId))
                .thenReturn(List.of(msg(InterviewMessageRole.ASSISTANT, 1, "What is a race condition?", null)));
        when(ai.evaluateInterviewAnswerForConcept(concept, "What is a race condition?", "my answer")).thenReturn(rubric(0.8));
        when(ai.generateInterviewQuestionForConcept(any(), anyList())).thenReturn(new AiInterviewQuestionResponse("Next one?"));

        InterviewMessageResponse reply = service.sendMessage(sessionId, user, new SendInterviewMessageRequest("my answer"));

        assertThat(reply.content()).isEqualTo("Next one?");
        assertThat(reply.score()).isEqualTo(80);
        assertThat(reply.feedback()).isEqualTo("feedback");
        ArgumentCaptor<InterviewMessage> saved = ArgumentCaptor.forClass(InterviewMessage.class);
        verify(messages, times(2)).save(saved.capture());
        assertThat(saved.getAllValues().get(0).getRole()).isEqualTo(InterviewMessageRole.USER);
        assertThat(saved.getAllValues().get(0).getScore()).isEqualTo(80);
    }

    @Test
    void anAnswerIsStillKeptWhenTheAiGraderIsDown() {
        when(messages.findByInterviewSessionIdOrderBySequenceNumberAsc(sessionId))
                .thenReturn(List.of(msg(InterviewMessageRole.ASSISTANT, 1, "Q?", null)));
        when(ai.evaluateInterviewAnswerForConcept(any(), anyString(), anyString())).thenReturn(null);
        when(ai.generateInterviewQuestionForConcept(any(), anyList())).thenReturn(new AiInterviewQuestionResponse("Next?"));

        InterviewMessageResponse reply = service.sendMessage(sessionId, user, new SendInterviewMessageRequest("answer"));

        assertThat(reply.score()).isNull();
        verify(messages, times(2)).save(any());
    }

    @Test
    void afterTheLastAllowedAnswerNoNewQuestionIsGenerated() {
        List<InterviewMessage> history = new java.util.ArrayList<>();
        history.add(msg(InterviewMessageRole.ASSISTANT, 1, "Q1", null));
        for (int i = 0; i < InterviewService.MAX_ANSWERS - 1; i++) {
            history.add(msg(InterviewMessageRole.USER, 2 + 2 * i, "a", 50));
            history.add(msg(InterviewMessageRole.ASSISTANT, 3 + 2 * i, "q", null));
        }
        when(messages.findByInterviewSessionIdOrderBySequenceNumberAsc(sessionId)).thenReturn(history);
        when(ai.evaluateInterviewAnswerForConcept(any(), anyString(), anyString())).thenReturn(rubric(0.5));

        InterviewMessageResponse reply = service.sendMessage(sessionId, user, new SendInterviewMessageRequest("last"));

        assertThat(reply.content()).isEqualTo(InterviewService.LAST_QUESTION_REPLY);
        verify(ai, never()).generateInterviewQuestionForConcept(any(), anyList());
    }

    @Test
    void completingAveragesTheScoredAnswersAndRecordsEvidenceOnce() {
        List<InterviewMessage> history = List.of(
                msg(InterviewMessageRole.ASSISTANT, 1, "Q", null),
                msg(InterviewMessageRole.USER, 2, "a1", 100),
                msg(InterviewMessageRole.ASSISTANT, 3, "Q", null),
                msg(InterviewMessageRole.USER, 4, "a2", 40),
                msg(InterviewMessageRole.USER, 5, "unscored (AI was down)", null));
        when(messages.findByInterviewSessionIdOrderBySequenceNumberAsc(sessionId)).thenReturn(history);

        InterviewResultResponse r = service.completeInterview(sessionId, user);

        assertThat(r.score()).isEqualTo(70);
        assertThat(r.status()).isEqualTo("COMPLETED");
        ArgumentCaptor<CreatePerformanceRecordRequest> rec = ArgumentCaptor.forClass(CreatePerformanceRecordRequest.class);
        verify(performance).createRecord(rec.capture());
        assertThat(rec.getValue().activityType()).isEqualTo(ActivityType.INTERVIEW);
        assertThat(rec.getValue().success()).isTrue();
        assertThat(rec.getValue().attemptCount()).isEqualTo(3);
        verify(progression).onActivity(user, concept, ActivityType.INTERVIEW, true, false);
        verify(publisher).publishEvent(any(ActivityEvidenceEvent.class));

        // second call: same result, no duplicate evidence
        service.completeInterview(sessionId, user);
        verify(performance, times(1)).createRecord(any());
    }

    @Test
    void completingWithoutAnyAnswerRecordsNoEvidence() {
        when(messages.findByInterviewSessionIdOrderBySequenceNumberAsc(sessionId))
                .thenReturn(List.of(msg(InterviewMessageRole.ASSISTANT, 1, "Q", null)));

        InterviewResultResponse r = service.completeInterview(sessionId, user);

        assertThat(r.score()).isZero();
        verifyNoInteractions(performance, progression, publisher);
    }
}
