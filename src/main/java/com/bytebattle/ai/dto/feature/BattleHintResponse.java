package com.bytebattle.ai.dto.feature;

import com.fasterxml.jackson.annotation.JsonInclude;
import java.util.Map;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record BattleHintResponse(
        Map<String, Object> concept,
        String question,
        HintData hint,
        Boolean fallback   // true only when this is a local template because the AI service was unavailable
) {
    /** Convenience constructor for real (non-fallback) AI responses. */
    public BattleHintResponse(Map<String, Object> concept, String question, HintData hint) {
        this(concept, question, hint, null);
    }

    public record HintData(
            Integer hintLevel,
            String hint,
            String nextStep
    ) {}
}
