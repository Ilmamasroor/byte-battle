package com.bytebattle.byte_battle_backend.curriculum;

import com.bytebattle.byte_battle_backend.common.ApiResponse;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/concepts")
public class ConceptController {

    private final ConceptService conceptService;

    public ConceptController(ConceptService conceptService) {
        this.conceptService = conceptService;
    }

    // GET /api/concepts/{conceptId}
    @GetMapping("/{conceptId}")
    public ApiResponse<ConceptResponseDTO> getConceptById(@PathVariable UUID conceptId) {
        return ApiResponse.success(conceptService.getConceptById(conceptId));
    }
}