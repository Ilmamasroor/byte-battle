package com.bytebattle.coding.dto;


import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.util.UUID;

public record CreateCodingChallengeRequest(
        @NotNull UUID conceptId,
        @NotBlank String title,
        String description,
        @NotBlank String difficulty,
        @NotBlank String language,
        String inputDescription,
        String outputDescription,
        String constraints,
        String starterCode,
        @NotBlank String solutionCode,
        String testCases,
        Integer timeLimitMs,
        Integer memoryLimitMb
) {}