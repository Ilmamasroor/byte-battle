package com.bytebattle.debugging.dto;


import com.bytebattle.debugging.enums.ErrorCategory;
import lombok.Builder;

@Builder
public record DebugResponse(
        ErrorCategory category,
        String diagnosis,
        boolean aiExplanationAvailable
) {}
