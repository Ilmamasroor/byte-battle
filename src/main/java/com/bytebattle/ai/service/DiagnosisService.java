package com.bytebattle.ai.service;


import com.bytebattle.ai.dto.AiRequest;
import com.bytebattle.ai.dto.AiResponse;
import com.bytebattle.ai.prompt.AiPromptBuilder;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class DiagnosisService {

    private final AiPromptBuilder promptBuilder;
    private final AiService aiService;

    public DiagnosisService(AiPromptBuilder promptBuilder, AiService aiService) {
        this.promptBuilder = promptBuilder;
        this.aiService = aiService;
    }

    /** Wraps a Debugging module ErrorCategory result into the shared AI contract. */
    public AiResponse diagnose(UUID userId, UUID conceptId, String activityType, String errorCategory,
                                String errorMessage, String sourceCode, String executionStatus,
                                Integer executionTimeMs, Integer testCasesPassed, Integer testCasesTotal) {

        AiRequest request = promptBuilder.baseRequest("DIAGNOSIS", userId, conceptId)
                .diagnosis(AiRequest.DiagnosisInfo.builder()
                        .activityType(activityType)
                        .errorCategory(errorCategory)
                        .errorMessage(errorMessage)
                        .sourceCode(sourceCode)
                        .executionStatus(executionStatus)
                        .executionTimeMs(executionTimeMs)
                        .testCasesPassed(testCasesPassed)
                        .testCasesTotal(testCasesTotal)
                        .build())
                .build();

        return aiService.process(request);
    }
}