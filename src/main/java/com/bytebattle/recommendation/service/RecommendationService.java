package com.bytebattle.recommendation.service;

import com.bytebattle.curriculum.Concept;
import com.bytebattle.curriculum.ConceptRepository;
import com.bytebattle.exception.BadRequestException;
import com.bytebattle.exception.ResourceNotFoundException;
import com.bytebattle.performance.dto.PerformanceSummaryResponse;
import com.bytebattle.performance.service.PerformanceService;
import com.bytebattle.recommendation.dto.CreateRecommendationRequest;
import com.bytebattle.recommendation.dto.NextBestActionResponse;
import com.bytebattle.recommendation.dto.RecommendationResponse;
import com.bytebattle.recommendation.entity.Recommendation;
import com.bytebattle.recommendation.enums.RecommendationActivityType;
import com.bytebattle.recommendation.enums.RecommendationPriority;
import com.bytebattle.recommendation.enums.RecommendationSource;
import com.bytebattle.recommendation.enums.RecommendationType;
import com.bytebattle.recommendation.repository.RecommendationRepository;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
public class RecommendationService {

    private static final Logger log =
            LoggerFactory.getLogger(RecommendationService.class);

    private static final int MAX_PAGE_SIZE = 100;
    private static final int MAX_TITLE = 255;

    private final RecommendationRepository repository;
    private final PerformanceService performanceService;
    private final ConceptRepository conceptRepository;

    public RecommendationService(
            RecommendationRepository repository,
            PerformanceService performanceService,
            ConceptRepository conceptRepository) {

        this.repository = repository;
        this.performanceService = performanceService;
        this.conceptRepository = conceptRepository;
    }

    /*
     * ============================================================
     * CREATE RECOMMENDATION
     * ============================================================
     *
     * ADMIN / INTERNAL USE
     *
     * The userId is intentionally accepted here because an admin
     * or internal recommendation-generation process may need to
     * create a recommendation for a specific learner.
     *
     * Normal learners must never use this endpoint.
     */
    @Transactional
    public RecommendationResponse create(
            CreateRecommendationRequest request) {

        validateConceptExists(request.conceptId());

        Recommendation candidate = Recommendation.builder()
                .userId(request.userId().trim())
                .conceptId(request.conceptId())
                .type(request.type())
                .source(request.source())
                .priority(request.priority())
                .title(truncate(request.title().trim(), MAX_TITLE))
                .message(request.message())
                .reason(request.reason())
                .isCompleted(false)
                .expiresAt(parseExpiry(request.expiresAt()))
                .build();

        return toResponse(upsertActive(candidate));
    }

    /*
     * ============================================================
     * ACTIVE RECOMMENDATIONS
     * ============================================================
     */
    @Transactional(readOnly = true)
    public List<RecommendationResponse> listActiveForUser(
            String userId) {

        return repository
                .findActive(userId, Instant.now())
                .stream()
                .map(this::toResponse)
                .toList();
    }

    /*
     * ============================================================
     * RECOMMENDATION HISTORY
     * ============================================================
     */
    @Transactional(readOnly = true)
    public List<RecommendationResponse> listAllForUser(
            String userId,
            int page,
            int size) {

        int safePage = Math.max(page, 0);

        int safeSize = Math.min(
                Math.max(size, 1),
                MAX_PAGE_SIZE
        );

        PageRequest pageable =
                PageRequest.of(safePage, safeSize);

        return repository
                .findByUserIdOrderByCreatedAtDesc(userId, pageable)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    /*
     * ============================================================
     * NEXT BEST ACTION
     * ============================================================
     *
     * Highest priority wins.
     *
     * If priorities are equal:
     * newest recommendation wins.
     */
    @Transactional(readOnly = true)
    public Optional<NextBestActionResponse> nextBestAction(
            String userId) {

        return repository
                .findActive(userId, Instant.now())
                .stream()
                .max(
                        Comparator
                                .<Recommendation>comparingInt(
                                        recommendation ->
                                                priorityWeight(
                                                        recommendation.getPriority()
                                                )
                                )
                                .thenComparing(
                                        Recommendation::getCreatedAt
                                )
                )
                .map(this::toNextBestAction);
    }

    /*
     * ============================================================
     * COMPLETE RECOMMENDATION
     * ============================================================
     *
     * Ownership is enforced in the repository query:
     *
     * recommendationId + userId
     *
     * Therefore User A cannot complete User B's recommendation.
     */
    @Transactional
    public RecommendationResponse markCompleted(
            UUID recommendationId,
            String userId) {

        Recommendation recommendation =
                repository
                        .findByIdAndUserId(
                                recommendationId,
                                userId
                        )
                        .orElseThrow(
                                () -> new ResourceNotFoundException(
                                        "Recommendation not found"
                                )
                        );

        recommendation.setIsCompleted(true);

        return toResponse(
                repository.save(recommendation)
        );
    }

    /*
     * ============================================================
     * DELETE RECOMMENDATION
     * ============================================================
     *
     * Ownership is checked before deletion.
     */
    @Transactional
    public void delete(
            UUID recommendationId,
            String userId) {

        Recommendation recommendation =
                repository
                        .findByIdAndUserId(
                                recommendationId,
                                userId
                        )
                        .orElseThrow(
                                () -> new ResourceNotFoundException(
                                        "Recommendation not found"
                                )
                        );

        repository.delete(recommendation);
    }

    /*
     * ============================================================
     * GENERATE FROM PERFORMANCE
     * ============================================================
     *
     * Deterministic recommendation generation.
     *
     * Performance evidence is used as the source.
     * AI is NOT responsible for deciding whether the performance
     * signal exists.
     */
    @Transactional
    public List<RecommendationResponse> generateFromPerformance(
            String userId) {

        PerformanceSummaryResponse summary =
                performanceService.getSummary(userId);

        if (summary == null) {
            return List.of();
        }

        Collection<String> weakConcepts =
                summary.weakConcepts();

        if (weakConcepts == null || weakConcepts.isEmpty()) {
            return List.of();
        }

        List<RecommendationResponse> result =
                new ArrayList<>();

        for (String rawConceptId : weakConcepts) {

            if (rawConceptId == null ||
                    rawConceptId.isBlank()) {

                log.warn(
                        "Skipping empty weak concept ID for user {}",
                        userId
                );

                continue;
            }

            UUID conceptId;

            try {

                conceptId =
                        UUID.fromString(
                                rawConceptId.trim()
                        );

            } catch (IllegalArgumentException exception) {

                log.warn(
                        "Skipping weak concept with invalid ID: {}",
                        rawConceptId
                );

                continue;
            }

            /*
             * Do not create a recommendation for a concept
             * that does not exist.
             */
            if (!conceptRepository.existsById(conceptId)) {

                log.warn(
                        "Skipping recommendation for missing concept: {}",
                        conceptId
                );

                continue;
            }

            Recommendation recommendation =
                    upsertActive(
                            Recommendation.builder()
                                    .userId(userId)
                                    .conceptId(conceptId)
                                    .type(
                                            RecommendationType.REVISE_CONCEPT
                                    )
                                    .source(
                                            RecommendationSource.PERFORMANCE_SIGNAL
                                    )
                                    .priority(
                                            RecommendationPriority.HIGH
                                    )
                                    .title(
                                            "Revise this concept before your next battle"
                                    )
                                    .message(
                                            "Your accuracy on this concept is below 50%."
                                    )
                                    .reason(
                                            "Derived from low average accuracy in performance records."
                                    )
                                    .isCompleted(false)
                                    .build()
                    );

            result.add(
                    toResponse(recommendation)
            );
        }

        return result;
    }

    /*
     * ============================================================
     * UPSERT ACTIVE RECOMMENDATION
     * ============================================================
     *
     * Prevents duplicate active recommendations for the same:
     *
     * user
     * concept
     * type
     * source
     *
     * Existing recommendation is refreshed.
     */
    private Recommendation upsertActive(
            Recommendation candidate) {

        return repository
                .findFirstByUserIdAndConceptIdAndTypeAndSourceAndIsCompletedFalse(
                        candidate.getUserId(),
                        candidate.getConceptId(),
                        candidate.getType(),
                        candidate.getSource()
                )
                .map(existing -> {

                    existing.setPriority(
                            candidate.getPriority()
                    );

                    existing.setTitle(
                            candidate.getTitle()
                    );

                    existing.setMessage(
                            candidate.getMessage()
                    );

                    existing.setReason(
                            candidate.getReason()
                    );

                    existing.setExpiresAt(
                            candidate.getExpiresAt()
                    );

                    return repository.save(existing);
                })
                .orElseGet(
                        () -> repository.save(candidate)
                );
    }

    /*
     * ============================================================
     * PRIORITY WEIGHT
     * ============================================================
     *
     * Do NOT use enum.ordinal() for business logic.
     *
     * Explicit weights make the business rule independent of
     * enum declaration order.
     */
    private int priorityWeight(
            RecommendationPriority priority) {

        return switch (priority) {

            case LOW -> 1;

            case MEDIUM -> 2;

            case HIGH -> 3;

            case CRITICAL -> 4;
        };
    }

    /*
     * ============================================================
     * ACTIVITY TYPE
     * ============================================================
     */
    private RecommendationActivityType activityTypeFor(
            RecommendationType type) {

        return switch (type) {

            case REVISE_CONCEPT,
                 ADJUST_DIFFICULTY ->
                    RecommendationActivityType.LEARNING;

            case PRACTICE_CODING ->
                    RecommendationActivityType.CODING;

            case RETRY_BATTLE ->
                    RecommendationActivityType.BATTLE;

            case TAKE_INTERVIEW ->
                    RecommendationActivityType.INTERVIEW;
        };
    }

    /*
     * ============================================================
     * NEXT BEST ACTION MAPPER
     * ============================================================
     */
    private NextBestActionResponse toNextBestAction(
            Recommendation recommendation) {

        String conceptName =
                conceptRepository
                        .findById(
                                recommendation.getConceptId()
                        )
                        .map(Concept::getName)
                        .orElse(null);

        String reason =
                recommendation.getMessage() != null &&
                        !recommendation.getMessage().isBlank()
                        ? recommendation.getMessage()
                        : recommendation.getReason();

        return new NextBestActionResponse(

                recommendation.getId(),

                recommendation.getConceptId(),

                conceptName,

                activityTypeFor(
                        recommendation.getType()
                ),

                recommendation.getPriority(),

                recommendation.getTitle(),

                reason
        );
    }

    /*
     * ============================================================
     * RESPONSE MAPPER
     * ============================================================
     */
    private RecommendationResponse toResponse(
            Recommendation recommendation) {

        return RecommendationResponse.builder()

                .id(recommendation.getId())

                .userId(recommendation.getUserId())

                .conceptId(recommendation.getConceptId())

                .type(recommendation.getType())

                .source(recommendation.getSource())

                .priority(recommendation.getPriority())

                .title(recommendation.getTitle())

                .message(recommendation.getMessage())

                .reason(recommendation.getReason())

                .isCompleted(
                        recommendation.getIsCompleted()
                )

                .createdAt(
                        recommendation.getCreatedAt()
                )

                .expiresAt(
                        recommendation.getExpiresAt()
                )

                .build();
    }

    /*
     * ============================================================
     * EXPIRY PARSER
     * ============================================================
     */
    private Instant parseExpiry(String value) {

        if (value == null ||
                value.isBlank()) {

            return null;
        }

        try {

            Instant expiry =
                    Instant.parse(value.trim());

            /*
             * Prevent creating already-expired recommendations.
             */
            if (expiry.isBefore(Instant.now())) {

                throw new BadRequestException(
                        "expiresAt must be in the future"
                );
            }

            return expiry;

        } catch (DateTimeParseException exception) {

            throw new BadRequestException(
                    "expiresAt must be an ISO-8601 instant, e.g. 2026-12-31T00:00:00Z"
            );
        }
    }

    /*
     * ============================================================
     * CONCEPT VALIDATION
     * ============================================================
     */
    private void validateConceptExists(
            UUID conceptId) {

        if (!conceptRepository.existsById(conceptId)) {

            throw new ResourceNotFoundException(
                    "Concept not found"
            );
        }
    }

    /*
     * ============================================================
     * TITLE LENGTH PROTECTION
     * ============================================================
     */
    private String truncate(
            String text,
            int maxLength) {

        if (text == null) {
            return null;
        }

        return text.length() > maxLength
                ? text.substring(0, maxLength)
                : text;
    }
}