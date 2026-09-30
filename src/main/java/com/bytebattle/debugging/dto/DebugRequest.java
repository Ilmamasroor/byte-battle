package com.bytebattle.debugging.dto;


import jakarta.validation.constraints.NotNull;

import java.util.UUID;

public record DebugRequest(
        @NotNull UUID submissionId
) {}