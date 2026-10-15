package com.bytebattle.ai.dto.feature;

import com.fasterxml.jackson.annotation.JsonInclude;
import java.util.Map;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record MnemonicResponse(
        Map<String, Object> concept,
        MnemonicData mnemonic,
        Boolean fallback   // true only when this is a local template because the AI service was unavailable
) {
    /** Convenience constructor for real (non-fallback) AI responses. */
    public MnemonicResponse(Map<String, Object> concept, MnemonicData mnemonic) {
        this(concept, mnemonic, null);
    }

    public record MnemonicData(
            String mnemonic,
            String memoryTip
    ) {}
}
