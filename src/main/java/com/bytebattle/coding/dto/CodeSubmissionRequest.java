package com.bytebattle.coding.dto;


import jakarta.validation.constraints.NotBlank;

public record CodeSubmissionRequest(
        @NotBlank String sourceCode,
        @NotBlank String language
) {}