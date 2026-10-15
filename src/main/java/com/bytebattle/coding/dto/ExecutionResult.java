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

    /**
     * Per-case result. {@code input}/{@code expectedOutput}/{@code actualOutput} are internal only; they must
     * pass through {@link TestCaseResultResponse#from} before reaching a learner, which strips hidden cases.
     */
    public record TestCaseOutcome(
            int testCaseNumber,
            boolean passed,
            String actualOutput,
            String expectedOutput,
            String input,
            boolean hidden,
            String status,
            Integer timeMs,
            Integer memoryKb) {
    }

    public boolean unavailable() {
        return status == CodingSubmissionStatus.EXECUTION_UNAVAILABLE;
    }

    /** Typed "could not run" outcome: Judge0 disabled, unreachable, timed out or internally broken. */
    public static ExecutionResult unavailable(String reason) {
        return new ExecutionResult(false, 0, 0, 0, null, reason, List.of(),
                CodingSubmissionStatus.EXECUTION_UNAVAILABLE);
    }
}
