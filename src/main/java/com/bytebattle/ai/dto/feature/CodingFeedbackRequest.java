package com.bytebattle.ai.dto.feature;

import java.util.Map;

public record CodingFeedbackRequest(
        Map<String, Object> concept,
        Map<String, Object> diagnosis
) {}
