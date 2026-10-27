package com.bytebattle.battle.dto;


import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record CreateBattleQuestionRequest(
        @NotBlank String questionText,
        @NotBlank String questionType,
        String options,
        @NotBlank String correctAnswer,
        String explanation,
        @NotNull Integer points,
        @NotNull Integer displayOrder
) {}