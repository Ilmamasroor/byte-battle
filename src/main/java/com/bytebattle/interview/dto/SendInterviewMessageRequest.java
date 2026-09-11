package com.bytebattle.interview.dto;


import jakarta.validation.constraints.NotBlank;

public record SendInterviewMessageRequest(
        @NotBlank String content
) {}