package com.bytebattle.coding.enums;


public enum CodingSubmissionStatus {
    PENDING,
    RUNNING,
    PASSED,
    FAILED,
    COMPILATION_ERROR,
    RUNTIME_ERROR,
    TIMEOUT,
    /** Judge0 disabled, unreachable, timed out or returned an internal error. Never persisted as learner evidence. */
    EXECUTION_UNAVAILABLE
}
