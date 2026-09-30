package com.bytebattle.coding.dto;


public record UpdateCodingChallengeRequest(
        String title,
        String description,
        String difficulty,
        String starterCode,
        String solutionCode,
        String testCases
) {}