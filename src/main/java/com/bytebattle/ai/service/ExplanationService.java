package com.bytebattle.ai.service;


import com.bytebattle.ai.dto.AiRequest;
import com.bytebattle.ai.dto.AiResponse;
import com.bytebattle.ai.prompt.AiPromptBuilder;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class ExplanationService {

    private final AiPromptBuilder promptBuilder;
    private final AiService aiService;

    public ExplanationService(AiPromptBuilder promptBuilder, AiService aiService) {
        this.promptBuilder = promptBuilder;
        this.aiService = aiService;
    }

    public AiResponse explain(UUID userId, UUID conceptId) {
        AiRequest request = promptBuilder.baseRequest("EXPLANATION", userId, conceptId).build();
        return aiService.process(request);
    }
}
