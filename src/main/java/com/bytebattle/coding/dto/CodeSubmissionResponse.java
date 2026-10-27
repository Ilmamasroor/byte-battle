package com.bytebattle.coding.dto;

import com.bytebattle.coding.enums.CodingSubmissionStatus;
import lombok.Builder;

import java.util.List;
import java.util.UUID;

@Builder
public record CodeSubmissionResponse(
        UUID submissionId,
        CodingSubmissionStatus status,
        Integer executionTimeMs,
        Long memoryUsedBytes,
        Integer testCasesPassed,
        Integer testCasesTotal,
        String errorMessage,
        String aiFeedback,
        List<TestCaseResultResponse> testCaseResults
) {}
