package com.bytebattle.coding.dto;


import java.util.List;

public record ExecutionResult(
        boolean passed,
        int testCasesPassed,
        int testCasesTotal,
        int executionTimeMs,
        String errorMessage, // null on success
        List<TestCaseOutcome> testCaseOutcomes
) {
    public record TestCaseOutcome(int testCaseNumber, boolean passed, String actualOutput, String expectedOutput) {}
}
