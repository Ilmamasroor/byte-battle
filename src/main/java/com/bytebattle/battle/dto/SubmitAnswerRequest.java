package com.bytebattle.battle.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.util.UUID;

/** One answer inside a battle session. Correctness is decided server-side only. */
public record SubmitAnswerRequest(
        @NotNull UUID battleQuestionId,
        @NotBlank String answer,
        @NotNull @Min(0) Integer timeTakenSeconds
) {
}
