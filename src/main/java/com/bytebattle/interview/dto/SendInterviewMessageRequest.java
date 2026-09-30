package com.bytebattle.interview.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record SendInterviewMessageRequest(

        @NotBlank(message = "Message content is required")
        @Size(max = 5000, message = "Message must not exceed 5000 characters")
        String content

) {
}