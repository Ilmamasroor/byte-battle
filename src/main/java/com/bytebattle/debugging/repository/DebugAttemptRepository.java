package com.bytebattle.debugging.repository;

import com.bytebattle.debugging.entity.DebugAttempt;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface DebugAttemptRepository extends JpaRepository<DebugAttempt, UUID> {

    List<DebugAttempt> findTop10ByUserIdAndExerciseIdOrderByCreatedAtDesc(UUID userId, UUID exerciseId);

    Optional<DebugAttempt> findTopByUserIdAndExerciseIdOrderByCreatedAtDesc(UUID userId, UUID exerciseId);

    long countByUserIdAndExerciseId(UUID userId, UUID exerciseId);
}
