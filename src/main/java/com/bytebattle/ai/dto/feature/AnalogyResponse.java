package com.bytebattle.ai.dto.feature;

import java.util.Map;

public record AnalogyResponse(
        Map<String, Object> concept,
        String analogy,
        String connection,
        String memoryTip
) {}
