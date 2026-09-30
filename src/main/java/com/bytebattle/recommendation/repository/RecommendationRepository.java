package com.bytebattle.recommendation.repository;

import com.bytebattle.recommendation.entity.Recommendation;
import com.bytebattle.recommendation.enums.RecommendationSource;
import com.bytebattle.recommendation.enums.RecommendationType;

import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface RecommendationRepository
        extends JpaRepository<Recommendation, UUID> {

    /**
     * Find active recommendations for a specific user.
     *
     * Active means:
     * 1. Belongs to the authenticated user
     * 2. Not completed
     * 3. Not expired
     */
    @Query("""
            SELECT r
            FROM Recommendation r
            WHERE r.userId = :userId
              AND r.isCompleted = false
              AND (r.expiresAt IS NULL OR r.expiresAt > :now)
            ORDER BY r.createdAt DESC
            """)
    List<Recommendation> findActive(
            @Param("userId") String userId,
            @Param("now") Instant now
    );

    /**
     * Get recommendation history for one specific user.
     *
     * Pageable prevents uncontrolled large result sets.
     */
    List<Recommendation> findByUserIdOrderByCreatedAtDesc(
            String userId,
            Pageable pageable
    );

    /**
     * Find one recommendation only if it belongs to the
     * requested user.
     *
     * This prevents User A from accessing User B's
     * recommendation by ID.
     */
    Optional<Recommendation> findByIdAndUserId(
            UUID id,
            String userId
    );

    /**
     * Find an existing incomplete recommendation for the
     * same user, concept, type and source.
     *
     * Used by the service to refresh an existing recommendation
     * instead of creating another duplicate.
     */
    Optional<Recommendation>
    findFirstByUserIdAndConceptIdAndTypeAndSourceAndIsCompletedFalse(
            String userId,
            UUID conceptId,
            RecommendationType type,
            RecommendationSource source
    );
}