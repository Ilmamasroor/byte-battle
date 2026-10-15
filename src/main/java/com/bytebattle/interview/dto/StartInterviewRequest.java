package com.bytebattle.interview.dto;


import jakarta.validation.constraints.NotBlank;
import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.NotNull;

import java.util.UUID;

public record StartInterviewRequest(
        @JsonProperty(access = JsonProperty.Access.READ_ONLY) UUID userId,
        @NotNull UUID conceptId,
        @NotBlank String difficulty
) {
    /** userId is never read from the request body; controllers set it from the authenticated user. */
    public StartInterviewRequest withUserId(UUID userId) {
        return new StartInterviewRequest(userId, conceptId, difficulty);
    }
}
