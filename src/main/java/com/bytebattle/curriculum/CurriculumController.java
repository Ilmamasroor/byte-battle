package com.bytebattle.curriculum;

import com.bytebattle.common.ApiResponse;
import com.bytebattle.common.PageResponse;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.web.bind.annotation.*;

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

    // GET /api/curriculum/domains?page=0&size=20
    @GetMapping("/domains")
    public ApiResponse<PageResponse<CurriculumDomainResponseDTO>> getAllDomains(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        Pageable pageable = PageRequest.of(page, size);
        return ApiResponse.success(curriculumService.getAllDomains(pageable));
    }

    // GET /api/curriculum/domains/{domainId}/topics?page=0&size=20
    @GetMapping("/domains/{domainId}/topics")
    public ApiResponse<PageResponse<TopicResponseDTO>> getTopicsByDomain(
            @PathVariable UUID domainId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        Pageable pageable = PageRequest.of(page, size);
        return ApiResponse.success(curriculumService.getTopicsByDomain(domainId, pageable));
    }

    // GET /api/curriculum/topics/{topicId}/concepts?page=0&size=20
    @GetMapping("/topics/{topicId}/concepts")
    public ApiResponse<PageResponse<ConceptResponseDTO>> getConceptsByTopic(
            @PathVariable UUID topicId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        Pageable pageable = PageRequest.of(page, size);
        return ApiResponse.success(conceptService.getConceptsByTopic(topicId, pageable));
    }
}