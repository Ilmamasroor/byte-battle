package com.bytebattle.coding.execution;

import org.springframework.stereotype.Component;

import com.bytebattle.coding.dto.ExecutionRequest;
import com.bytebattle.coding.dto.ExecutionResult;

import java.util.List;

/**
 * TEMPORARY STUB — for local testing only.
 * Always reports every test case as passed without running anything.
 * MUST be replaced with a real sandboxed executor (separate process/container)
 * before this module handles real user-submitted code. Do not deploy as-is.
 */
@Component
public class StubCodeExecutor implements CodeExecutor {

    @Override
    public ExecutionResult execute(ExecutionRequest request) {
        return new ExecutionResult(
                true, 1, 1, 0, null,
                List.of(new ExecutionResult.TestCaseOutcome(1, true, "stub-output", "stub-output")));
    }
}