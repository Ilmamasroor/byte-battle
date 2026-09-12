package com.bytebattle.ai.dto.feature;

import java.util.Map;

public record BattleHintResponse(
        Map<String, Object> concept,
        String question,
        HintData hint
) {
    public record HintData(
            Integer hintLevel,
            String hint,
            String nextStep
    ) {}
}
