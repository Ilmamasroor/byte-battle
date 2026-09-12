package com.bytebattle.interview.service;

import com.bytebattle.interview.dto.*;
import com.bytebattle.interview.entity.InterviewMessage;
import com.bytebattle.interview.entity.InterviewSession;
import com.bytebattle.interview.enums.InterviewMessageRole;
import com.bytebattle.interview.enums.InterviewStatus;
import com.bytebattle.interview.repository.InterviewMessageRepository;
import com.bytebattle.interview.repository.InterviewSessionRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Service
public class InterviewService {

    private final InterviewSessionRepository sessionRepository;
    private final InterviewMessageRepository messageRepository;

    public InterviewService(InterviewSessionRepository sessionRepository,
                             InterviewMessageRepository messageRepository) {
        this.sessionRepository = sessionRepository;
        this.messageRepository = messageRepository;
    }

    @Transactional
    public InterviewSessionResponse startInterview(StartInterviewRequest request) {
        InterviewSession session = sessionRepository.save(InterviewSession.builder()
                .userId(request.userId())
                .conceptId(request.conceptId())
                .difficulty(request.difficulty())
                .status(InterviewStatus.IN_PROGRESS)
                .build());

        messageRepository.save(InterviewMessage.builder()
                .interviewSessionId(session.getId())
                .role(InterviewMessageRole.ASSISTANT)
                .content(placeholderQuestion(request.difficulty(), 1))
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

    @Transactional
    public InterviewMessageResponse sendMessage(UUID sessionId, UUID userId, SendInterviewMessageRequest request) {
        InterviewSession session = requireInProgressSession(sessionId, userId);

        long currentCount = messageRepository.countByInterviewSessionId(sessionId);
        int nextSeq = (int) currentCount + 1;

        messageRepository.save(InterviewMessage.builder()
                .interviewSessionId(sessionId)
                .role(InterviewMessageRole.USER)
                .content(request.content())
                .sequenceNumber(nextSeq)
                .build());

        InterviewMessage assistantReply = messageRepository.save(InterviewMessage.builder()
                .interviewSessionId(sessionId)
                .role(InterviewMessageRole.ASSISTANT)
                .content(placeholderQuestion(session.getDifficulty(), nextSeq + 1))
                .sequenceNumber(nextSeq + 1)
                .build());

        return toMessageResponse(assistantReply);
    }

    @Transactional
    public InterviewResultResponse completeInterview(UUID sessionId, UUID userId) {
        InterviewSession session = sessionRepository.findByIdAndUserId(sessionId, userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Session not found"));

        long totalMessages = messageRepository.countByInterviewSessionId(sessionId);

        session.setStatus(InterviewStatus.COMPLETED);
        session.setCompletedAt(Instant.now());
        session.setScore(scoreFor(totalMessages));
        sessionRepository.save(session);

        return InterviewResultResponse.builder()
                .sessionId(session.getId())
                .score(session.getScore())
                .totalMessages((int) totalMessages)
                .status(session.getStatus().name())
                .build();
    }

    public void deleteSession(UUID sessionId, UUID userId) {
        sessionRepository.findByIdAndUserId(sessionId, userId)
                .ifPresentOrElse(
                        sessionRepository::delete,
                        () -> { throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Session not found"); }
                );
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

    /** TEMPORARY STUB — real question generation belongs to AiInterviewService (doc §38). */
    private String placeholderQuestion(String difficulty, int sequenceNumber) {
        return "[stub question #" + sequenceNumber + ", difficulty=" + difficulty
                + "] Tell me about a time you solved a challenging problem.";
    }

    /** Deterministic placeholder scoring — replace once real evaluation criteria exist. */
    private int scoreFor(long totalMessages) {
        return (int) Math.min(100, totalMessages * 10);
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
                .build();
    }
    


}