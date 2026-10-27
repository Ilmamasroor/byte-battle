package com.bytebattle.ai.dto.feature;

import com.fasterxml.jackson.annotation.JsonInclude;
@JsonInclude(JsonInclude.Include.NON_NULL)
public record AiInterviewQuestionResponse(
        String question,
        Boolean fallback   // true only when this is a local template because the AI service was unavailable
) {
    /** Convenience constructor for real (non-fallback) AI responses. */
    public AiInterviewQuestionResponse(String question) {
        this(question, null);
    }
}
