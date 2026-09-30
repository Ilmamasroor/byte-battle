package com.bytebattle.interview.service;

import com.bytebattle.interview.dto.InterviewMessageResponse;
import com.bytebattle.interview.dto.InterviewResultResponse;
import com.bytebattle.interview.dto.InterviewSessionResponse;
import com.bytebattle.interview.dto.SendInterviewMessageRequest;
import com.bytebattle.interview.dto.StartInterviewRequest;
import com.bytebattle.interview.entity.InterviewMessage;
import com.bytebattle.interview.entity.InterviewSession;
import com.bytebattle.interview.enums.InterviewMessageRole;
import com.bytebattle.interview.enums.InterviewStatus;
import com.bytebattle.interview.repository.InterviewMessageRepository;
import com.bytebattle.interview.repository.InterviewSessionRepository;

import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Service
public class InterviewService {

    private static final int MAX_PAGE_SIZE = 100;

    private final InterviewSessionRepository sessionRepository;
    private final InterviewMessageRepository messageRepository;

    public InterviewService(
            InterviewSessionRepository sessionRepository,
            InterviewMessageRepository messageRepository) {

        this.sessionRepository = sessionRepository;
        this.messageRepository = messageRepository;
    }

    // ============================================================
    // START INTERVIEW
    // ============================================================

    @Transactional
    public InterviewSessionResponse startInterview(
            StartInterviewRequest request,
            String userId) {

        String difficulty = request.difficulty().trim();

        InterviewSession session =
                InterviewSession.builder()
                        .userId(userId)
                        .conceptId(request.conceptId())
                        .difficulty(difficulty)
                        .status(InterviewStatus.IN_PROGRESS)
                        .build();

        InterviewSession savedSession =
                sessionRepository.save(session);

        /*
         * AI part intentionally ignored for now.
         *
         * If you already have an opening-question mechanism,
         * connect it here.
         */

        InterviewMessage firstMessage =
                InterviewMessage.builder()
                        .interviewSessionId(savedSession.getId())
                        .role(InterviewMessageRole.ASSISTANT)
                        .content(
                                "Welcome to your interview. "
                                + "Let's begin."
                        )
                        .sequenceNumber(1)
                        .build();

        messageRepository.save(firstMessage);

        return toSessionResponse(savedSession);
    }

    // ============================================================
    // GET ONE INTERVIEW
    // ============================================================

    @Transactional(readOnly = true)
    public InterviewSessionResponse getSession(
            UUID sessionId,
            String userId) {

        InterviewSession session =
                sessionRepository
                        .findByIdAndUserId(sessionId, userId)
                        .orElseThrow(() ->
                                new ResponseStatusException(
                                        HttpStatus.NOT_FOUND,
                                        "Interview session not found"
                                )
                        );

        return toSessionResponse(session);
    }

    // ============================================================
    // LIST USER INTERVIEWS
    // ============================================================

    @Transactional(readOnly = true)
    public List<InterviewSessionResponse> listForUser(
            String userId,
            int page,
            int size) {

        int safePage = Math.max(page, 0);

        int safeSize =
                Math.min(
                        Math.max(size, 1),
                        MAX_PAGE_SIZE
                );

        PageRequest pageable =
                PageRequest.of(
                        safePage,
                        safeSize,
                        Sort.by(
                                Sort.Direction.DESC,
                                "createdAt"
                        )
                );

        return sessionRepository
                .findByUserIdOrderByCreatedAtDesc(
                        userId,
                        pageable
                )
                .getContent()
                .stream()
                .map(this::toSessionResponse)
                .toList();
    }

    // ============================================================
    // GET MESSAGES
    // ============================================================

    @Transactional(readOnly = true)
    public List<InterviewMessageResponse> getMessages(
            UUID sessionId,
            String userId) {

        /*
         * First verify that this interview belongs
         * to the authenticated user.
         */
        sessionRepository
                .findByIdAndUserId(sessionId, userId)
                .orElseThrow(() ->
                        new ResponseStatusException(
                                HttpStatus.NOT_FOUND,
                                "Interview session not found"
                        )
                );

        return messageRepository
                .findByInterviewSessionIdOrderBySequenceNumberAsc(
                        sessionId
                )
                .stream()
                .map(this::toMessageResponse)
                .toList();
    }

    // ============================================================
    // SEND MESSAGE
    // ============================================================

    @Transactional
    public InterviewMessageResponse sendMessage(
            UUID sessionId,
            String userId,
            SendInterviewMessageRequest request) {

        InterviewSession session =
                requireInProgressSession(
                        sessionId,
                        userId
                );

        String content = request.content().trim();

        int nextSequence =
                messageRepository
                        .findTopByInterviewSessionIdOrderBySequenceNumberDesc(
                                sessionId
                        )
                        .map(message ->
                                message.getSequenceNumber() + 1
                        )
                        .orElse(1);

        InterviewMessage userMessage =
                InterviewMessage.builder()
                        .interviewSessionId(sessionId)
                        .role(InterviewMessageRole.USER)
                        .content(content)
                        .sequenceNumber(nextSequence)
                        .build();

        messageRepository.save(userMessage);

        /*
         * AI response intentionally ignored.
         *
         * Temporary response so the Interview API can be
         * tested independently of the AI module.
         */
        InterviewMessage response =
                InterviewMessage.builder()
                        .interviewSessionId(sessionId)
                        .role(InterviewMessageRole.ASSISTANT)
                        .content(
                                "Thank you for your answer. "
                                + "Please continue with the interview."
                        )
                        .sequenceNumber(nextSequence + 1)
                        .build();

        InterviewMessage savedResponse =
                messageRepository.save(response);

        return toMessageResponse(savedResponse);
    }

    // ============================================================
    // COMPLETE INTERVIEW
    // ============================================================

    @Transactional
    public InterviewResultResponse completeInterview(
            UUID sessionId,
            String userId) {

        InterviewSession session =
                requireInProgressSession(
                        sessionId,
                        userId
                );

        long totalMessages =
                messageRepository.countByInterviewSessionId(
                        sessionId
                );

        session.setStatus(InterviewStatus.COMPLETED);
        session.setCompletedAt(Instant.now());

        /*
         * AI/evaluation part intentionally ignored.
         * Keep score null until the real evaluation logic
         * is connected.
         */
        session.setScore(null);

        sessionRepository.save(session);

        return InterviewResultResponse.builder()
                .sessionId(session.getId())
                .score(session.getScore())
                .totalMessages((int) totalMessages)
                .status(session.getStatus().name())
                .build();
    }

    // ============================================================
    // DELETE INTERVIEW
    // ============================================================

    @Transactional
    public void deleteSession(
            UUID sessionId,
            String userId) {

        InterviewSession session =
                sessionRepository
                        .findByIdAndUserId(
                                sessionId,
                                userId
                        )
                        .orElseThrow(() ->
                                new ResponseStatusException(
                                        HttpStatus.NOT_FOUND,
                                        "Interview session not found"
                                )
                        );

        List<InterviewMessage> messages =
                messageRepository
                        .findByInterviewSessionIdOrderBySequenceNumberAsc(
                                sessionId
                        );

        messageRepository.deleteAll(messages);

        sessionRepository.delete(session);
    }

    // ============================================================
    // REQUIRE IN-PROGRESS SESSION
    // ============================================================

    private InterviewSession requireInProgressSession(
            UUID sessionId,
            String userId) {

        InterviewSession session =
                sessionRepository
                        .findByIdAndUserId(
                                sessionId,
                                userId
                        )
                        .orElseThrow(() ->
                                new ResponseStatusException(
                                        HttpStatus.NOT_FOUND,
                                        "Interview session not found"
                                )
                        );

        if (session.getStatus() != InterviewStatus.IN_PROGRESS) {

            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Interview is already completed or abandoned"
            );
        }

        return session;
    }

    // ============================================================
    // MAPPERS
    // ============================================================

    private InterviewSessionResponse toSessionResponse(
            InterviewSession session) {

        return InterviewSessionResponse.builder()
                .id(session.getId())
                .userId(session.getUserId())
                .conceptId(session.getConceptId())
                .status(session.getStatus())
                .difficulty(session.getDifficulty())
                .startedAt(session.getStartedAt())
                .completedAt(session.getCompletedAt())
                .score(session.getScore())
                .build();
    }

    private InterviewMessageResponse toMessageResponse(
            InterviewMessage message) {

        return InterviewMessageResponse.builder()
                .id(message.getId())
                .role(message.getRole())
                .content(message.getContent())
                .sequenceNumber(message.getSequenceNumber())
                .createdAt(message.getCreatedAt())
                .build();
    }
}