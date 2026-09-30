package com.bytebattle.ai.dto.feature;

import java.util.Map;

public record MnemonicResponse(
        Map<String, Object> concept,
        MnemonicData mnemonic
) {
    public record MnemonicData(
            String mnemonic,
            String memoryTip
    ) {}
}
