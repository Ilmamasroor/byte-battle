package com.bytebattle.battle.dto;
import com.bytebattle.battle.enums.BattleType;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.util.UUID;

public record CreateBattleRequest(
        @NotNull UUID conceptId,
        @NotBlank String title,
        String description,
        @NotNull BattleType battleType,
        @NotBlank String difficulty,
        @Min(1) Integer totalQuestions,
        @Min(1) Integer timeLimitSeconds,
        @Min(1) Integer totalLives
) {}