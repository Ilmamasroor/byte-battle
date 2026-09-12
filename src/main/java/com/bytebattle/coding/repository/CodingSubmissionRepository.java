package com.bytebattle.coding.repository;


import org.springframework.data.jpa.repository.JpaRepository;

import com.bytebattle.coding.entities.CodingSubmission;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface CodingSubmissionRepository extends JpaRepository<CodingSubmission, UUID> {

    List<CodingSubmission> findByUserIdAndCodingChallengeId(UUID userId, UUID codingChallengeId);

    Optional<CodingSubmission> findByIdAndUserId(UUID id, UUID userId);
}
