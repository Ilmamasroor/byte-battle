package com.bytebattle.ai.dto.feature;

import java.util.List;

public record BossBattleResponse(
        String scenario,
        List<String> suggestedOptions
) {}
