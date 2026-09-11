package com.bytebattle.learning.service;

import com.bytebattle.learning.dto.*;
import com.bytebattle.learning.entity.LearningProgress;
import com.bytebattle.learning.enums.LearningStage;
import com.bytebattle.learning.repository.LearningProgressRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class LearningService {

    private final LearningProgressRepository repository;

    public LearningProgressResponse startConcept(StartLearningRequest request) {
        LearningProgress progress = repository
                .findByUserIdAndConceptId(request.userId(), request.conceptId())
                .orElseGet(() -> createNewProgress(request.userId(), request.conceptId()));

        return toResponse(repository.save(progress));
    }

    public LearningProgressResponse getProgress(UUID progressId) {
        return repository.findById(progressId)
                .map(this::toResponse)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Progress not found: " + progressId));
    }

    public LearningProgressResponse completeStage(CompleteStageRequest request) {
        return repository.findById(request.progressId())
                .map(this::advanceStage)
                .map(repository::save)
                .map(this::toResponse)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Progress not found: " + request.progressId()));
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
                .progressPercentage(0)
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

	public Optional<LearningProgress> getProgress(UUID userId, UUID conceptId) {
		// TODO Auto-generated method stub
		return null;
	}
}