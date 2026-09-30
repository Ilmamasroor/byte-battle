package com.bytebattle.learning.dto;

import jakarta.validation.constraints.NotNull;

import java.util.UUID;

// CHANGED: userId removed, it now comes from the token
public record StartLearningRequest(
        @NotNull UUID conceptId
) {}