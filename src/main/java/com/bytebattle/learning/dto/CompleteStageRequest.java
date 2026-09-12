package com.bytebattle.learning.dto;


import jakarta.validation.constraints.NotNull;

import java.util.UUID;

public record CompleteStageRequest(
        @NotNull UUID progressId
) {}