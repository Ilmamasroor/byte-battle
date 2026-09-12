package com.bytebattle.ai.controller;


import com.bytebattle.ai.dto.AiResponse;
import com.bytebattle.ai.service.ExplanationService;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/ai")
public class AiController {

    private final ExplanationService explanationService;

    public AiController(ExplanationService explanationService) {
        this.explanationService = explanationService;
    }

    @PostMapping("/explanation")
    public AiResponse explanation(@RequestParam UUID userId, @RequestParam UUID conceptId) {
        return explanationService.explain(userId, conceptId);
    }
}