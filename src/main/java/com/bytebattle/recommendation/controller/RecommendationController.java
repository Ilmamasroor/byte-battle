package com.bytebattle.recommendation.controller;


import com.bytebattle.recommendation.dto.*;
import com.bytebattle.recommendation.service.RecommendationService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/recommendations")
public class RecommendationController {

    private final RecommendationService recommendationService;

    public RecommendationController(RecommendationService recommendationService) {
        this.recommendationService = recommendationService;
    }

    @PostMapping
    public ResponseEntity<RecommendationResponse> create(@RequestBody @Valid CreateRecommendationRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(recommendationService.create(request));
    }

    @GetMapping
    public ResponseEntity<List<RecommendationResponse>> listActive(@RequestParam UUID userId) {
        return ResponseEntity.ok(recommendationService.listActiveForUser(userId));
    }

    @GetMapping("/all")
    public ResponseEntity<List<RecommendationResponse>> listAll(@RequestParam UUID userId) {
        return ResponseEntity.ok(recommendationService.listAllForUser(userId));
    }

    @PostMapping("/{id}/complete")
    public ResponseEntity<RecommendationResponse> complete(@PathVariable UUID id, @RequestParam UUID userId) {
        return ResponseEntity.ok(recommendationService.markCompleted(id, userId));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable UUID id, @RequestParam UUID userId) {
        recommendationService.delete(id, userId);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/generate")
    public ResponseEntity<List<RecommendationResponse>> generate(@RequestParam UUID userId) {
        return ResponseEntity.ok(recommendationService.generateFromPerformance(userId));
    }
}
