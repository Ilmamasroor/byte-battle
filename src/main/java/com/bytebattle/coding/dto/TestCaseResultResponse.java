package com.bytebattle.coding.dto;


import lombok.Builder;

@Builder
public record TestCaseResultResponse(
        Integer testCaseNumber,
        Boolean passed,
        String actualOutput,   // null if execution failed before producing output
        String expectedOutput  // only shown for FAILED cases, not solutionCode itself
) {}