package com.bytebattle.coding.dto;

import com.bytebattle.coding.enums.CodingSubmissionStatus;

import java.util.List;

public record ExecutionResult(
        boolean passed,
        int testCasesPassed,
        int testCasesTotal,
        int executionTimeMs,
        Long memoryUsedBytes,
        String errorMessage,
        List<TestCaseOutcome> testCaseOutcomes,
        CodingSubmissionStatus status
) {
    public record TestCaseOutcome(int testCaseNumber, boolean passed, String actualOutput, String expectedOutput) {}
}
