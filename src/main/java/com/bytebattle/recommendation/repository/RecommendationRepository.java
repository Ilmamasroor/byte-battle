package com.bytebattle.recommendation.repository;


import com.bytebattle.recommendation.entity.Recommendation;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface RecommendationRepository extends JpaRepository<Recommendation, UUID> {

    List<Recommendation> findByUserIdAndIsCompletedFalse(UUID userId);

    List<Recommendation> findByUserId(UUID userId);

    Optional<Recommendation> findByIdAndUserId(UUID id, UUID userId);
}