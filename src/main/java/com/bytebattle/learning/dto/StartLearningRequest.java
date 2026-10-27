package com.bytebattle.learning.dto;


import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.NotNull;

import java.util.UUID;

public record StartLearningRequest(
        @JsonProperty(access = JsonProperty.Access.READ_ONLY) UUID userId,
        @NotNull UUID conceptId
) {
    /** userId is never read from the request body; controllers set it from the authenticated user. */
    public StartLearningRequest withUserId(UUID userId) {
        return new StartLearningRequest(userId, conceptId);
    }
}
