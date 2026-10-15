package com.bytebattle.coding.dto;

import lombok.Builder;

import java.util.List;
import java.util.UUID;

// SECURITY: excludes solutionCode and hidden test cases entirely — doc §19. Never add them here.
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
        Integer memoryLimitMb,
        List<SampleTestCase> sampleTestCases,
        Integer totalTestCases,
        Integer hiddenTestCases
) {
    /** A visible (sample) test case: the learner may see its input and expected output. */
    public record SampleTestCase(int caseNumber, String input, String expectedOutput) {}
}
