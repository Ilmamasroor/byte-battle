package com.bytebattle.battle.dto;

import lombok.Builder;

import java.util.UUID;

@Builder
public record StartBattleResponse(
        UUID sessionId,
        BattleQuestionResponse firstQuestion,
        Integer remainingLives,
        Integer timeLimitSeconds
) {}