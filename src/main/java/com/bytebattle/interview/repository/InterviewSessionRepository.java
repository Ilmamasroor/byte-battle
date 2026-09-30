package com.bytebattle.interview.repository;

import com.bytebattle.interview.entity.InterviewSession;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface InterviewSessionRepository extends JpaRepository<InterviewSession, UUID> {

    List<InterviewSession> findByUserIdOrderByCreatedAtDesc(
            String userId,
            Pageable pageable
    );

    Optional<InterviewSession> findByIdAndUserId(
            UUID id,
            String userId
    );

	Optional<InterviewSession> findByUserId(String string);
}