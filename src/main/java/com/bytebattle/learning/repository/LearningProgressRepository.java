package com.bytebattle.learning.repository;

import com.bytebattle.learning.entity.LearningProgress;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface LearningProgressRepository
        extends JpaRepository<LearningProgress, UUID> {

    /**
     * Find learning progress for one user and one concept.
     */
    Optional<LearningProgress> findByUserIdAndConceptId(
            String userId,
            UUID conceptId
    );

    /**
     * Find all learning progress records belonging
     * to one user.
     */
    List<LearningProgress> findByUserId(
            String userId
    );
}