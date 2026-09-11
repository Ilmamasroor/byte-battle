package com.bytebattle.battle.dto;
import java.util.UUID;

import lombok.Builder;

@Builder
public record BattleResultResponse(
        UUID sessionId,
        Integer finalScore,
        Integer totalQuestions,
        Integer correctAnswers,
        Boolean won
) {}