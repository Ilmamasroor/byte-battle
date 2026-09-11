package com.bytebattle.interview.repository;


import com.bytebattle.interview.entity.InterviewSession;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface InterviewSessionRepository extends JpaRepository<InterviewSession, UUID> {

    List<InterviewSession> findByUserId(UUID userId);

    Optional<InterviewSession> findByIdAndUserId(UUID id, UUID userId);
}