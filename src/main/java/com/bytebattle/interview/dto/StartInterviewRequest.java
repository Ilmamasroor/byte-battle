package com.bytebattle.interview.dto;


import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.util.UUID;

public record StartInterviewRequest(
        @NotNull UUID userId,
        @NotNull UUID conceptId,
        @NotBlank String difficulty
) {}