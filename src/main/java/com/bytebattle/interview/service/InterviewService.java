package com.bytebattle.interview.service;

import com.bytebattle.ai.dto.feature.AiInterviewEvaluateResponse;
import com.bytebattle.ai.service.AiFeatureService;
import com.bytebattle.ai.service.PersonalizationAiService.ActivityEvidence;
import com.bytebattle.interview.dto.*;
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
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * AI-driven technical interview. The AI service interprets (asks the questions, grades each answer against
 * a rubric); this service decides: it stores the answers, computes the session score as the mean of the
 * rubric scores, and turns the finished interview into verified evidence.
 *
 * Slow AI calls deliberately run outside a database transaction.
 */
@Service
public class InterviewService {

    /** Questions per interview; after this many answers the learner is asked to complete the session. */
    static final int MAX_ANSWERS = 5;
    static final int PASS_SCORE = 60;
    static final String LAST_QUESTION_REPLY =
            "That was the last question. Complete the interview to see your result.";

    private final InterviewSessionRepository sessionRepository;
    private final InterviewMessageRepository messageRepository;
    private final AiFeatureService aiFeatureService;
    private final PerformanceService performanceService;
    private final ProgressionService progressionService;
    private final ApplicationEventPublisher eventPublisher;

    public InterviewService(InterviewSessionRepository sessionRepository,
                            InterviewMessageRepository messageRepository,
                            AiFeatureService aiFeatureService,
                            PerformanceService performanceService,
                            ProgressionService progressionService,
                            ApplicationEventPublisher eventPublisher) {
        this.sessionRepository = sessionRepository;
        this.messageRepository = messageRepository;
        this.aiFeatureService = aiFeatureService;
        this.performanceService = performanceService;
        this.progressionService = progressionService;
        this.eventPublisher = eventPublisher;
    }

    public InterviewSessionResponse startInterview(StartInterviewRequest request) {
        // AI first (it also validates the concept): nothing is persisted if the concept does not exist
        String firstQuestion = aiFeatureService
                .generateInterviewQuestionForConcept(request.conceptId(), new ArrayList<>())
                .question();

        InterviewSession session = sessionRepository.save(InterviewSession.builder()
                .userId(request.userId())
                .conceptId(request.conceptId())
                .difficulty(request.difficulty())
                .status(InterviewStatus.IN_PROGRESS)
                .build());

        messageRepository.save(InterviewMessage.builder()
                .interviewSessionId(session.getId())
                .role(InterviewMessageRole.ASSISTANT)
                .content(firstQuestion)
                .sequenceNumber(1)
                .build());

        return toSessionResponse(session);
    }

    public InterviewSessionResponse getSession(UUID sessionId, UUID userId) {
        return sessionRepository.findByIdAndUserId(sessionId, userId)
                .map(this::toSessionResponse)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Session not found"));
    }

    public List<InterviewSessionResponse> listForUser(UUID userId) {
        return sessionRepository.findByUserId(userId).stream()
                .map(this::toSessionResponse)
                .toList();
    }

    public List<InterviewMessageResponse> getMessages(UUID sessionId) {
        return messageRepository.findByInterviewSessionIdOrderBySequenceNumberAsc(sessionId).stream()
                .map(this::toMessageResponse)
                .toList();
    }

    public InterviewMessageResponse sendMessage(UUID sessionId, UUID userId, SendInterviewMessageRequest request) {
        InterviewSession session = requireInProgressSession(sessionId, userId);

        List<InterviewMessage> history = messageRepository.findByInterviewSessionIdOrderBySequenceNumberAsc(sessionId);
        String question = history.stream()
                .filter(m -> m.getRole() == InterviewMessageRole.ASSISTANT)
                .reduce((first, second) -> second)
                .map(InterviewMessage::getContent)
                .orElse("");
        int nextSeq = history.size() + 1;
        long answersSoFar = history.stream().filter(m -> m.getRole() == InterviewMessageRole.USER).count();

        // 1) grade the answer (null when the AI service is down: the answer is kept, just unscored)
        AiInterviewEvaluateResponse evaluation =
                aiFeatureService.evaluateInterviewAnswerForConcept(session.getConceptId(), question, request.content());
        Integer score = scoreOf(evaluation);
        String feedback = evaluation == null ? null : evaluation.feedback();

        messageRepository.save(InterviewMessage.builder()
                .interviewSessionId(sessionId)
                .role(InterviewMessageRole.USER)
                .content(request.content())
                .sequenceNumber(nextSeq)
                .score(score)
                .feedback(feedback)
                .build());

        // 2) next question, or the closing prompt after the last allowed answer
        String reply;
        if (answersSoFar + 1 >= MAX_ANSWERS) {
            reply = LAST_QUESTION_REPLY;
        } else {
            List<Object> transcript = new ArrayList<>();
            for (InterviewMessage m : history) {
                transcript.add(turn(m.getRole(), m.getContent()));
            }
            transcript.add(turn(InterviewMessageRole.USER, request.content()));
            reply = aiFeatureService
                    .generateInterviewQuestionForConcept(session.getConceptId(), transcript)
                    .question();
        }

        InterviewMessage assistantReply = messageRepository.save(InterviewMessage.builder()
                .interviewSessionId(sessionId)
                .role(InterviewMessageRole.ASSISTANT)
                .content(reply)
                .sequenceNumber(nextSeq + 1)
                .build());

        // The reply carries the evaluation of the answer that was just given
        return InterviewMessageResponse.builder()
                .id(assistantReply.getId())
                .role(assistantReply.getRole())
                .content(assistantReply.getContent())
                .sequenceNumber(assistantReply.getSequenceNumber())
                .createdAt(assistantReply.getCreatedAt())
                .score(score)
                .feedback(feedback)
                .rubric(rubricOf(evaluation))
                .build();
    }

    static java.util.Map<String, Double> rubricOf(AiInterviewEvaluateResponse e) {
        if (e == null) {
            return null;
        }
        java.util.Map<String, Double> r = new LinkedHashMap<>();
        r.put("conceptualCorrectness", clamp(e.conceptualCorrectness()));
        r.put("completeness", clamp(e.completeness()));
        r.put("technicalClarity", clamp(e.technicalClarity()));
        r.put("reasoning", clamp(e.reasoning()));
        r.put("explanation", clamp(e.explanation()));
        return r;
    }

    private static double clamp(Double v) {
        return v == null ? 0.0 : Math.max(0.0, Math.min(1.0, v));
    }

    @Transactional
    public InterviewResultResponse completeInterview(UUID sessionId, UUID userId) {
        InterviewSession session = sessionRepository.findByIdAndUserId(sessionId, userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Session not found"));

        List<InterviewMessage> messages = messageRepository.findByInterviewSessionIdOrderBySequenceNumberAsc(sessionId);

        if (session.getStatus() == InterviewStatus.COMPLETED) {
            return toResult(session, messages.size()); // idempotent: evidence is recorded only once
        }

        List<Integer> scores = messages.stream()
                .filter(m -> m.getRole() == InterviewMessageRole.USER && m.getScore() != null)
                .map(InterviewMessage::getScore)
                .toList();
        int answers = (int) messages.stream().filter(m -> m.getRole() == InterviewMessageRole.USER).count();
        int score = scores.isEmpty() ? 0 : (int) Math.round(scores.stream().mapToInt(Integer::intValue).average().orElse(0));

        Instant now = Instant.now();
        session.setStatus(InterviewStatus.COMPLETED);
        session.setCompletedAt(now);
        session.setScore(score);
        sessionRepository.save(session);

        recordEvidence(session, score, answers, now);
        return toResult(session, messages.size());
    }

    public void deleteSession(UUID sessionId, UUID userId) {
        sessionRepository.findByIdAndUserId(sessionId, userId)
                .ifPresentOrElse(
                        sessionRepository::delete,
                        () -> { throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Session not found"); }
                );
    }

    // ------------------------------------------------------------------ helpers

    private void recordEvidence(InterviewSession session, int score, int answers, Instant completedAt) {
        // Nothing was answered: no evidence of communication either way
        if (answers == 0) {
            return;
        }
        double accuracy = score / 100.0;
        boolean passed = score >= PASS_SCORE;
        long seconds = session.getStartedAt() == null ? 0
                : Math.max(0, Math.min(Duration.between(session.getStartedAt(), completedAt).toSeconds(), 86_400));

        performanceService.createRecord(new CreatePerformanceRecordRequest(
                session.getUserId(), session.getConceptId(), ActivityType.INTERVIEW,
                score, accuracy, (int) seconds, answers, passed));

        progressionService.onActivity(session.getUserId(), session.getConceptId(), ActivityType.INTERVIEW, passed, false);

        eventPublisher.publishEvent(new ActivityEvidenceEvent(new ActivityEvidence(
                session.getUserId(), session.getConceptId(), "interview", accuracy, score,
                answers, (int) seconds, 0, null, null, passed)));
    }

    /** Mean of the five rubric dimensions, as 0-100. Null when nothing could be evaluated. */
    static Integer scoreOf(AiInterviewEvaluateResponse e) {
        if (e == null) {
            return null;
        }
        double[] parts = {
                orZero(e.conceptualCorrectness()), orZero(e.completeness()), orZero(e.technicalClarity()),
                orZero(e.reasoning()), orZero(e.explanation())};
        double sum = 0;
        for (double p : parts) {
            sum += Math.max(0.0, Math.min(1.0, p));
        }
        return (int) Math.round(sum / parts.length * 100.0);
    }

    private static double orZero(Double v) {
        return v == null ? 0.0 : v;
    }

    private static Map<String, Object> turn(InterviewMessageRole role, String content) {
        Map<String, Object> t = new LinkedHashMap<>();
        t.put("role", role == InterviewMessageRole.USER ? "learner" : "interviewer");
        t.put("content", content);
        return t;
    }

    /**
     * findByIdAndUserId() -> filter(IN_PROGRESS) -> orElseGet(...).
     * An empty Optional here means either "session doesn't exist" or "session
     * exists but isn't IN_PROGRESS" — both collapse to the same empty state.
     * throwAppropriateStatusError() does one extra lookup ONLY on that empty
     * path (never on the success path) to tell those two cases apart and
     * throw the correct 404 vs 409.
     */
    private InterviewSession requireInProgressSession(UUID sessionId, UUID userId) {
        return sessionRepository.findByIdAndUserId(sessionId, userId)
                .filter(session -> session.getStatus() == InterviewStatus.IN_PROGRESS)
                .orElseGet(() -> throwAppropriateStatusError(sessionId, userId));
    }

    private InterviewSession throwAppropriateStatusError(UUID sessionId, UUID userId) {
        return (InterviewSession) sessionRepository.findByIdAndUserId(sessionId, userId)
                .map(session -> { throw new ResponseStatusException(
                        HttpStatus.CONFLICT, "Interview is not in progress"); })
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Session not found"));
    }

    private InterviewResultResponse toResult(InterviewSession session, int totalMessages) {
        return InterviewResultResponse.builder()
                .sessionId(session.getId())
                .score(session.getScore())
                .totalMessages(totalMessages)
                .status(session.getStatus().name())
                .build();
    }

    private InterviewSessionResponse toSessionResponse(InterviewSession s) {
        return InterviewSessionResponse.builder()
                .id(s.getId()).userId(s.getUserId()).conceptId(s.getConceptId())
                .status(s.getStatus()).difficulty(s.getDifficulty())
                .startedAt(s.getStartedAt()).completedAt(s.getCompletedAt()).score(s.getScore())
                .build();
    }

    private InterviewMessageResponse toMessageResponse(InterviewMessage m) {
        return InterviewMessageResponse.builder()
                .id(m.getId()).role(m.getRole()).content(m.getContent())
                .sequenceNumber(m.getSequenceNumber()).createdAt(m.getCreatedAt())
                .score(m.getScore()).feedback(m.getFeedback())
                .build();
    }
}
