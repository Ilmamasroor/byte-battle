package com.bytebattle.interview.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.UUID;

public record StartInterviewRequest(

        @NotNull(message = "Concept ID is required")
        UUID conceptId,

        @NotBlank(message = "Difficulty is required")
        @Size(max = 30, message = "Difficulty must not exceed 30 characters")
        String difficulty

) {
}