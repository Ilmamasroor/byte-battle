package com.bytebattle.coding.testcase;

/**
 * One stdin/stdout test case of a coding challenge or debugging exercise.
 *
 * @param hidden when true the case is never revealed to learners (no input, expected or actual output)
 */
public record CodingTestCase(String input, String expectedOutput, boolean hidden) {

    public String inputOrEmpty() {
        return input == null ? "" : input;
    }

    public String expectedOrEmpty() {
        return expectedOutput == null ? "" : expectedOutput;
    }
}
