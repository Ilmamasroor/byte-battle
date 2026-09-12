package com.bytebattle.ai.controller;

import com.bytebattle.ai.dto.AiResponse;
import com.bytebattle.ai.dto.personalization.*;
import com.bytebattle.ai.service.ExplanationService;
import com.bytebattle.ai.service.PersonalizationAiService;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/ai")
public class AiController {

    private final ExplanationService explanationService;
    private final PersonalizationAiService personalizationAiService;

    public AiController(
            ExplanationService explanationService,
            PersonalizationAiService personalizationAiService) {

        this.explanationService = explanationService;
        this.personalizationAiService = personalizationAiService;
    }

    @PostMapping("/explanation")
    public AiResponse explanation(
            @RequestParam java.util.UUID userId,
            @RequestParam java.util.UUID conceptId) {

        return explanationService.explain(userId, conceptId);
    }

    @PostMapping("/onboarding")
    public ByteDnaAiResponse onboarding(
            @RequestBody OnboardingAiRequest request) {

        return personalizationAiService.onboard(request);
    }

    @PostMapping("/diagnose")
    public DiagnosisAiResponse diagnose(
            @RequestBody DiagnosisAiRequest request) {

        return personalizationAiService.diagnose(request);
    }

    @PostMapping("/diagnose/summary")
    public DiagnosisSummaryAiResponse diagnoseSummary(
            @RequestBody DiagnosisSummaryAiRequest request) {

        return personalizationAiService.diagnoseSummary(request);
    }

    @PostMapping("/recommend")
    public RecommendationAiResponse recommend(
            @RequestBody RecommendationAiRequest request) {

        return personalizationAiService.recommend(request);
    }

    @PostMapping("/byte-dna/evolve")
    public ByteDnaEvolutionResponse evolveByteDna(
            @RequestBody ByteDnaEvolutionRequest request) {

        return personalizationAiService.evolveByteDna(request);
    }
}
