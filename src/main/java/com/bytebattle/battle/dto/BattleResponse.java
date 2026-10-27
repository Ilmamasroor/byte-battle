package com.bytebattle.battle.dto;

import com.bytebattle.battle.enums.BattleStatus;
import com.bytebattle.battle.enums.BattleType;
import lombok.Builder;

import java.util.UUID;

@Builder
public record BattleResponse(
        UUID id,
        UUID conceptId,
        String title,
        String description,
        BattleType battleType,
        String difficulty,
        Integer totalQuestions,
        Integer timeLimitSeconds,
        Integer totalLives,
        BattleStatus status
) {}