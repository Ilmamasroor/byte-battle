package com.bytebattle.battle.dto;


import lombok.Builder;

import java.util.UUID;

// SECURITY: this DTO intentionally excludes correctAnswer and explanation.
// Never add those fields here — see doc section 11.
@Builder
public record BattleQuestionResponse(
        UUID id,
        String questionText,
        String questionType,
        String options,
        Integer points,
        Integer displayOrder
) {}
