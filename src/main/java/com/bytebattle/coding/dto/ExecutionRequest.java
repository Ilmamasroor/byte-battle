package com.bytebattle.coding.dto;


public record ExecutionRequest(
        String sourceCode,
        String language,
        String testCasesJson,
        Integer timeLimitMs,
        Integer memoryLimitMb
) {}