package com.bytebattle.learning.repository;

import com.bytebattle.learning.entity.LearningProgress;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface LearningProgressRepository extends JpaRepository<LearningProgress, UUID> {

    Optional<LearningProgress> findByUserIdAndConceptId(UUID userId, UUID conceptId);
 // LearningProgressRepository.java — add this line inside the interface
    List<LearningProgress> findByUserId(UUID userId);
}
