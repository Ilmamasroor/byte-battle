package com.bytebattle.debugging.repository;

import com.bytebattle.debugging.entity.DebugExercise;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface DebugExerciseRepository extends JpaRepository<DebugExercise, UUID> {

    List<DebugExercise> findByConceptIdOrderByCreatedAtAsc(UUID conceptId);

    List<DebugExercise> findAllByOrderByCreatedAtAsc();
}
