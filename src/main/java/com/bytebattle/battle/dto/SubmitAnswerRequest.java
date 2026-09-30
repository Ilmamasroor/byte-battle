package com.bytebattle.battle.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.UUID;

public record SubmitAnswerRequest(
        @NotNull UUID battleQuestionId,
        @NotBlank @Size(max = 255) String answer,
        @NotNull @Min(0) Integer timeTakenSeconds
) {}