package com.bytebattle.coding.repository;

import com.bytebattle.coding.entities.CodingSubmissionTestResult;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface CodingSubmissionTestResultRepository extends JpaRepository<CodingSubmissionTestResult, UUID> {

    List<CodingSubmissionTestResult> findBySubmissionIdOrderByCaseNumberAsc(UUID submissionId);
}
