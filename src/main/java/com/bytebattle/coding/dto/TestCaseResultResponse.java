package com.bytebattle.coding.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.Builder;

/**
 * Learner-facing per-test-case result. For hidden cases only caseNumber, passed, status, hidden and
 * timeMs are populated; input, expectedOutput and actualOutput are always null (and omitted from JSON).
 */
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public record TestCaseResultResponse(
        Integer caseNumber,
        Boolean passed,
        String status,
        Boolean hidden,
        Integer timeMs,
        String input,
        String expectedOutput,
        String actualOutput
) {

    private static final int MAX_OUTPUT_CHARS = 2000;

    public static TestCaseResultResponse from(ExecutionResult.TestCaseOutcome o) {
        if (o.hidden()) {
            return hiddenCase(o.testCaseNumber(), o.passed(), o.status(), o.timeMs());
        }
        return new TestCaseResultResponse(o.testCaseNumber(), o.passed(), o.status(), false, o.timeMs(),
                o.input(), o.expectedOutput(), truncate(o.actualOutput()));
    }

    public static TestCaseResultResponse hiddenCase(int number, boolean passed, String status, Integer timeMs) {
        return new TestCaseResultResponse(number, passed, status, true, timeMs, null, null, null);
    }

    public static String truncate(String value) {
        if (value == null || value.length() <= MAX_OUTPUT_CHARS) {
            return value;
        }
        return value.substring(0, MAX_OUTPUT_CHARS);
    }
}
