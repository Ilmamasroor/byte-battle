package com.bytebattle.coding.dto;

import lombok.Builder;

import java.util.UUID;

// SECURITY: excludes solutionCode entirely — doc §19. Never add it here.
@Builder
public record CodingChallengeResponse(
        UUID id,
        UUID conceptId,
        String title,
        String description,
        String difficulty,
        String language,
        String inputDescription,
        String outputDescription,
        String constraints,
        String starterCode,
        Integer timeLimitMs,
        Integer memoryLimitMb
) {}