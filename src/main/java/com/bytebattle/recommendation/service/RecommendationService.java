package com.bytebattle.recommendation.service;


import com.bytebattle.performance.dto.PerformanceSummaryResponse;
import com.bytebattle.performance.service.PerformanceService;
import com.bytebattle.recommendation.dto.*;
import com.bytebattle.recommendation.entity.Recommendation;
import com.bytebattle.recommendation.enums.RecommendationPriority;
import com.bytebattle.recommendation.enums.RecommendationSource;
import com.bytebattle.recommendation.enums.RecommendationType;
import com.bytebattle.recommendation.repository.RecommendationRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
public class RecommendationService {

    private final RecommendationRepository repository;
    private final PerformanceService performanceService;

    public RecommendationService(RecommendationRepository repository, PerformanceService performanceService) {
        this.repository = repository;
        this.performanceService = performanceService;
    }

    public RecommendationResponse create(CreateRecommendationRequest request) {
        Recommendation rec = repository.save(Recommendation.builder()
                .userId(request.userId())
                .conceptId(request.conceptId())
                .type(request.type())
                .source(request.source())
                .priority(request.priority())
                .title(request.title())
                .message(request.message())
                .reason(request.reason())
                .isCompleted(false)
                .expiresAt(Optional.ofNullable(request.expiresAt()).map(Instant::parse).orElse(null))
                .build());
        return toResponse(rec);
    }

    public List<RecommendationResponse> listActiveForUser(UUID userId) {
        return repository.findByUserIdAndIsCompletedFalse(userId).stream()
                .map(this::toResponse)
                .toList();
    }

    public List<RecommendationResponse> listAllForUser(UUID userId) {
        return repository.findByUserId(userId).stream()
                .map(this::toResponse)
                .toList();
    }

    public RecommendationResponse markCompleted(UUID recommendationId, UUID userId) {
        return repository.findByIdAndUserId(recommendationId, userId)
                .map(rec -> { rec.setIsCompleted(true); return rec; })
                .map(repository::save)
                .map(this::toResponse)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Recommendation not found"));
    }

    public void delete(UUID recommendationId, UUID userId) {
        repository.findByIdAndUserId(recommendationId, userId)
                .ifPresentOrElse(
                        repository::delete,
                        () -> { throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Recommendation not found"); }
                );
    }

    /**
     * Custom operation — doc §29-31: derive recommendations from Performance signals.
     * Deterministic rule-based logic, not AI (AI-generated recommendations are a
     * separate path via AiRecommendationService, built later in the AI module).
     */
    public List<RecommendationResponse> generateFromPerformance(UUID userId) {
        PerformanceSummaryResponse summary = performanceService.getSummary(userId);

        List<Recommendation> generated = summary.weakConcepts().stream()
                .map(conceptIdStr -> Recommendation.builder()
                        .userId(userId)
                        .conceptId(UUID.fromString(conceptIdStr))
                        .type(RecommendationType.REVISE_CONCEPT)
                        .source(RecommendationSource.PERFORMANCE_SIGNAL)
                        .priority(RecommendationPriority.HIGH)
                        .title("Revise this concept before your next battle")
                        .message("Your accuracy on this concept is below 50%.")
                        .reason("Derived from low average accuracy in performance records.")
                        .isCompleted(false)
                        .build())
                .toList();

        return repository.saveAll(generated).stream()
                .map(this::toResponse)
                .toList();
    }

    private RecommendationResponse toResponse(Recommendation r) {
        return RecommendationResponse.builder()
                .id(r.getId()).userId(r.getUserId()).conceptId(r.getConceptId())
                .type(r.getType()).source(r.getSource()).priority(r.getPriority())
                .title(r.getTitle()).message(r.getMessage()).reason(r.getReason())
                .isCompleted(r.getIsCompleted()).createdAt(r.getCreatedAt()).expiresAt(r.getExpiresAt())
                .build();
    }
}
