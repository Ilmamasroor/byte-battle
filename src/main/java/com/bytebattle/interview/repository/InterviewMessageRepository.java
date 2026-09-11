package com.bytebattle.interview.repository;


import com.bytebattle.interview.entity.InterviewMessage;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface InterviewMessageRepository extends JpaRepository<InterviewMessage, UUID> {

    List<InterviewMessage> findByInterviewSessionIdOrderBySequenceNumberAsc(UUID interviewSessionId);

    long countByInterviewSessionId(UUID interviewSessionId);
}