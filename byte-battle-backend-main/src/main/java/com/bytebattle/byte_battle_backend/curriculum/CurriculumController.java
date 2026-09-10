package com.bytebattle.byte_battle_backend.curriculum;

import com.bytebattle.byte_battle_backend.common.ApiResponse;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/curriculum")
public class CurriculumController {

    private final CurriculumService curriculumService;
    private final ConceptService conceptService;

    public CurriculumController(CurriculumService curriculumService, ConceptService conceptService) {
        this.curriculumService = curriculumService;
        this.conceptService = conceptService;
    }

    // GET /api/curriculum/domains
    @GetMapping("/domains")
    public ApiResponse<List<CurriculumDomainResponseDTO>> getAllDomains() {
        return ApiResponse.success(curriculumService.getAllDomains());
    }

    // GET /api/curriculum/domains/{domainId}/topics
    @GetMapping("/domains/{domainId}/topics")
    public ApiResponse<List<TopicResponseDTO>> getTopicsByDomain(@PathVariable UUID domainId) {
        return ApiResponse.success(curriculumService.getTopicsByDomain(domainId));
    }

    // GET /api/curriculum/topics/{topicId}/concepts
    @GetMapping("/topics/{topicId}/concepts")
    public ApiResponse<List<ConceptResponseDTO>> getConceptsByTopic(@PathVariable UUID topicId) {
        return ApiResponse.success(conceptService.getConceptsByTopic(topicId));
    }
}