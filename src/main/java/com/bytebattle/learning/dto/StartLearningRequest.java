package com.bytebattle.learning.dto;


import jakarta.validation.constraints.NotNull;

import java.util.UUID;

public record StartLearningRequest(
        @NotNull UUID userId,
        @NotNull UUID conceptId
) {}