package com.bytebattle.recommendation.repository;


import com.bytebattle.recommendation.entity.Recommendation;
import org.springframework.data.jpa.repository.JpaRepository;

import com.bytebattle.recommendation.enums.RecommendationType;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface RecommendationRepository extends JpaRepository<Recommendation, UUID> {

    List<Recommendation> findByUserIdAndIsCompletedFalse(UUID userId);

    List<Recommendation> findByUserId(UUID userId);

    Optional<Recommendation> findByIdAndUserId(UUID id, UUID userId);

    /** Used to keep AI-generated recommendations idempotent (same user + type + concept within a window). */
    boolean existsByUserIdAndTypeAndConceptIdAndCreatedAtAfter(
            UUID userId, RecommendationType type, UUID conceptId, Instant createdAfter);
}