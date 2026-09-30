package com.bytebattle.learner.repository;

import com.bytebattle.learner.entity.LearnerProfile;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface LearnerProfileRepository
        extends JpaRepository<LearnerProfile, UUID> {

    Optional<LearnerProfile> findByUser_Id(String userId);

    boolean existsByUser_Id(String userId);
}