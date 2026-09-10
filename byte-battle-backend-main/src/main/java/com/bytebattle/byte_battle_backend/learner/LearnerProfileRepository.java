package com.bytebattle.byte_battle_backend.learner;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface LearnerProfileRepository extends JpaRepository<LearnerProfile, UUID> {
    Optional<LearnerProfile> findByUser_Id(UUID userId);
    boolean existsByUser_Id(UUID userId);
}