package com.bytebattle.learning.service;

import com.bytebattle.learning.dto.CompleteStageRequest;
import com.bytebattle.learning.dto.LearningProgressResponse;
import com.bytebattle.learning.dto.StartLearningRequest;
import com.bytebattle.learning.entity.LearningProgress;
import com.bytebattle.learning.enums.LearningStage;
import com.bytebattle.learning.repository.LearningProgressRepository;

import lombok.RequiredArgsConstructor;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class LearningService {

    private final LearningProgressRepository repository;

    /**
     * Start learning a concept for the authenticated user.
     *
     * The userId is supplied by the security layer/controller,
     * not by StartLearningRequest.
     */
    @Transactional
    public LearningProgressResponse startConcept(
            StartLearningRequest request,
            String userId) {

        LearningProgress progress = repository
                .findByUserIdAndConceptId(
                        userId,
                        request.conceptId()
                )
                .orElseGet(() ->
                        createNewProgress(
                                userId,
                                request.conceptId()
                        )
                );

        return toResponse(
                repository.save(progress)
        );
    }

    /**
     * Get one learning progress record.
     *
     * Only the authenticated user's resource can be returned.
     */
    @Transactional(readOnly = true)
    public LearningProgressResponse getOwnedProgress(
            UUID progressId,
            String userId) {

        return toResponse(
                requireOwned(
                        progressId,
                        userId
                )
        );
    }

    /**
     * Complete the current learning stage and move
     * the learner to the next stage.
     */
    @Transactional
    public LearningProgressResponse completeStage(
            CompleteStageRequest request,
            String userId) {

        LearningProgress progress =
                requireOwned(
                        request.progressId(),
                        userId
                );

        LearningProgress updated =
                advanceStage(progress);

        return toResponse(
                repository.save(updated)
        );
    }

    /**
     * Get all learning progress records belonging
     * to the authenticated user.
     */
    @Transactional(readOnly = true)
    public List<LearningProgressResponse> getAllForUser(
            String userId) {

        return repository
                .findByUserId(userId)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    /**
     * Delete a learning progress record owned by
     * the authenticated user.
     */
    @Transactional
    public void deleteProgress(
            UUID progressId,
            String userId) {

        repository.delete(
                requireOwned(
                        progressId,
                        userId
                )
        );
    }

    /**
     * Internal lookup used by other backend services.
     *
     * This is intentionally scoped by userId.
     */
    @Transactional(readOnly = true)
    public Optional<LearningProgress> getProgress(
            String userId,
            UUID conceptId) {

        return repository.findByUserIdAndConceptId(
                userId,
                conceptId
        );
    }

    /**
     * Verify that the requested learning progress belongs
     * to the authenticated user.
     *
     * If the resource exists but belongs to another user,
     * return 403 as required by the authorization checklist.
     */
    private LearningProgress requireOwned(
            UUID progressId,
            String userId) {

        LearningProgress progress =
                repository.findById(progressId)
                        .orElseThrow(() ->
                                new ResponseStatusException(
                                        HttpStatus.NOT_FOUND,
                                        "Progress not found"
                                )
                        );

        if (!progress.getUserId().equals(userId)) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "You do not have access to this progress"
            );
        }

        return progress;
    }

    /**
     * Create initial learning progress.
     */
    private LearningProgress createNewProgress(
            String userId,
            UUID conceptId) {

        return LearningProgress.builder()
                .userId(userId)
                .conceptId(conceptId)
                .currentStage(
                        LearningStage.UNDERSTAND
                )
                .completed(false)
                .progressPercentage(10)
                .build();
    }

    /**
     * Move the learner to the next stage.
     */
    private LearningProgress advanceStage(
            LearningProgress progress) {

        LearningStage current =
                progress.getCurrentStage();

        LearningStage next =
                nextStage(current);

        progress.setCurrentStage(next);
        progress.setProgressPercentage(
                percentageFor(next)
        );

        if (next == LearningStage.COMPLETED) {

            progress.setCompleted(true);

            if (progress.getCompletedAt() == null) {
                progress.setCompletedAt(
                        Instant.now()
                );
            }
        }

        return progress;
    }

    /**
     * Explicit learning state machine.
     */
    private LearningStage nextStage(
            LearningStage current) {

        if (current == null) {
            return LearningStage.UNDERSTAND;
        }

        return switch (current) {

            case UNDERSTAND ->
                    LearningStage.VISUALIZE;

            case VISUALIZE ->
                    LearningStage.RELATE;

            case RELATE ->
                    LearningStage.REMEMBER;

            case REMEMBER ->
                    LearningStage.BATTLE;

            case BATTLE ->
                    LearningStage.CODE;

            case CODE ->
                    LearningStage.DEBUG;

            case DEBUG ->
                    LearningStage.EXPLAIN;

            case EXPLAIN ->
                    LearningStage.INTERVIEW;

            case INTERVIEW ->
                    LearningStage.IMPROVE;

            case IMPROVE ->
                    LearningStage.COMPLETED;

            case COMPLETED ->
                    LearningStage.COMPLETED;
        };
    }

    /**
     * Progress percentage for each learning stage.
     */
    private Integer percentageFor(
            LearningStage stage) {

        return switch (stage) {

            case UNDERSTAND -> 10;

            case VISUALIZE -> 20;

            case RELATE -> 30;

            case REMEMBER -> 40;

            case BATTLE -> 55;

            case CODE -> 70;

            case DEBUG -> 80;

            case EXPLAIN -> 85;

            case INTERVIEW -> 90;

            case IMPROVE -> 95;

            case COMPLETED -> 100;
        };
    }

    /**
     * Convert entity into API response.
     */
    private LearningProgressResponse toResponse(
            LearningProgress progress) {

        return LearningProgressResponse.builder()
                .id(progress.getId())
                .userId(progress.getUserId())
                .conceptId(progress.getConceptId())
                .currentStage(
                        progress.getCurrentStage()
                )
                .completed(
                        progress.getCompleted()
                )
                .progressPercentage(
                        progress.getProgressPercentage()
                )
                .startedAt(
                        progress.getStartedAt()
                )
                .completedAt(
                        progress.getCompletedAt()
                )
                .build();
    }
}