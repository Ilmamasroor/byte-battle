package com.bytebattle.learning.service;

import com.bytebattle.learning.dto.*;
import com.bytebattle.learning.entity.LearningProgress;
import com.bytebattle.learning.enums.LearningStage;
import com.bytebattle.learning.repository.LearningProgressRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
public class LearningService {

    private final LearningProgressRepository repository;

    public LearningService(LearningProgressRepository repository) {
        this.repository = repository;
    }

    public LearningProgressResponse startConcept(StartLearningRequest request) {
        LearningProgress progress = repository
                .findByUserIdAndConceptId(request.userId(), request.conceptId())
                .orElseGet(() -> createNewProgress(request.userId(), request.conceptId()));

        return toResponse(repository.save(progress));
    }

    public LearningProgressResponse getProgress(UUID progressId) {
        return repository.findById(progressId)
                .map(this::toResponse)
                .orElseThrow(() ->
                        new IllegalArgumentException("Progress not found: " + progressId));
    }

    public LearningProgressResponse completeStage(CompleteStageRequest request) {
        return repository.findById(request.progressId())
                .map(this::advanceStage)
                .map(repository::save)
                .map(this::toResponse)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Progress not found: " + request.progressId()));
    }

    // ---- Ownership-checked variants: controllers MUST use these (never trust a bare progress id) ----

    public LearningProgressResponse getProgressForUser(UUID progressId, UUID userId) {
        return repository.findByIdAndUserId(progressId, userId)
                .map(this::toResponse)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Progress not found"));
    }

    /** Stages that only verified results may complete (see {@link #advanceIfAt}); a learner cannot skip them. */
    private static final java.util.Set<LearningStage> EVIDENCE_STAGES = java.util.EnumSet.of(
            LearningStage.BATTLE, LearningStage.CODE, LearningStage.DEBUG, LearningStage.INTERVIEW);

    public LearningProgressResponse completeStageForUser(CompleteStageRequest request, UUID userId) {
        return repository.findByIdAndUserId(request.progressId(), userId)
                .map(progress -> {
                    if (EVIDENCE_STAGES.contains(progress.getCurrentStage())) {
                        throw new ResponseStatusException(HttpStatus.CONFLICT,
                                "The " + progress.getCurrentStage() + " stage is completed by a passing result, not manually");
                    }
                    return progress;
                })
                .map(this::advanceStage)
                .map(repository::save)
                .map(this::toResponse)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Progress not found"));
    }

    public void deleteProgressForUser(UUID progressId, UUID userId) {
        repository.findByIdAndUserId(progressId, userId)
                .ifPresentOrElse(
                        repository::delete,
                        () -> { throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Progress not found"); }
                );
    }

    public List<LearningProgressResponse> getAllForUser(UUID userId) {
        return repository.findByUserId(userId).stream()
                .map(this::toResponse)
                .toList();
    }

    public void deleteProgress(UUID progressId) {
        repository.findById(progressId)
                .ifPresentOrElse(
                        repository::delete,
                        () -> { throw new ResponseStatusException(
                                HttpStatus.NOT_FOUND, "Progress not found: " + progressId); }
                );
    }

    private LearningProgress createNewProgress(UUID userId, UUID conceptId) {
        return LearningProgress.builder()
                .userId(userId)
                .conceptId(conceptId)
                .currentStage(LearningStage.UNDERSTAND)
                .completed(false)
                .progressPercentage(10)
                .build();
    }

    private LearningProgress advanceStage(LearningProgress progress) {
        LearningStage next = nextStage(progress.getCurrentStage());
        progress.setCurrentStage(next);
        progress.setProgressPercentage(percentageFor(next));

        if (next == LearningStage.COMPLETED) {
            progress.setCompleted(true);
            progress.setCompletedAt(Instant.now());
        }

        return progress;
    }

    private LearningStage nextStage(LearningStage current) {
        return switch (current) {
            case UNDERSTAND -> LearningStage.VISUALIZE;
            case VISUALIZE -> LearningStage.RELATE;
            case RELATE -> LearningStage.REMEMBER;
            case REMEMBER -> LearningStage.BATTLE;
            case BATTLE -> LearningStage.CODE;
            case CODE -> LearningStage.DEBUG;
            case DEBUG -> LearningStage.INTERVIEW;
            case INTERVIEW -> LearningStage.IMPROVE;
            case IMPROVE -> LearningStage.COMPLETED;
            case COMPLETED -> LearningStage.COMPLETED; // terminal — no further advance
        };
    }

    private Integer percentageFor(LearningStage stage) {
        return switch (stage) {
            case UNDERSTAND -> 10;
            case VISUALIZE -> 20;
            case RELATE -> 30;
            case REMEMBER -> 40;
            case BATTLE -> 55;
            case CODE -> 70;
            case DEBUG -> 80;
            case INTERVIEW -> 90;
            case IMPROVE -> 95;
            case COMPLETED -> 100;
        };
    }

    private LearningProgressResponse toResponse(LearningProgress p) {
        return LearningProgressResponse.builder()
                .id(p.getId())
                .userId(p.getUserId())
                .conceptId(p.getConceptId())
                .currentStage(p.getCurrentStage())
                .completed(p.getCompleted())
                .progressPercentage(p.getProgressPercentage())
                .startedAt(p.getStartedAt())
                .completedAt(p.getCompletedAt())
                .build();
    }

    /**
     * Server-side progression driven by verified evidence: moves the learner to the next stage only when
     * they are currently exactly at {@code expected} (so replaying an earlier stage never skips ahead).
     * No-op when the learner has not started the concept.
     */
    public Optional<LearningProgressResponse> advanceIfAt(UUID userId, UUID conceptId, LearningStage expected) {
        return repository.findByUserIdAndConceptId(userId, conceptId)
                .filter(p -> p.getCurrentStage() == expected)
                .map(this::advanceStage)
                .map(repository::save)
                .map(this::toResponse);
    }

    public Optional<LearningProgress> getProgress(UUID userId, UUID conceptId) {
        return repository.findByUserIdAndConceptId(userId, conceptId);
    }
}