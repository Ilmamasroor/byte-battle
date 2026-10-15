package com.bytebattle.recommendation.controller;


import com.bytebattle.recommendation.dto.*;
import com.bytebattle.recommendation.service.RecommendationService;
import jakarta.validation.Valid;
import com.bytebattle.security.CurrentUser;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/recommendations")
public class RecommendationController {

    private final RecommendationService recommendationService;
    private final CurrentUser currentUser;

    public RecommendationController(RecommendationService recommendationService, CurrentUser currentUser) {
        this.recommendationService = recommendationService;
        this.currentUser = currentUser;
    }

    @PostMapping
    public ResponseEntity<RecommendationResponse> create(@RequestBody @Valid CreateRecommendationRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(recommendationService.create(request.withUserId(currentUser.id())));
    }

    @GetMapping
    public ResponseEntity<List<RecommendationResponse>> listActive() {
        return ResponseEntity.ok(recommendationService.listActiveForUser(currentUser.id()));
    }

    @GetMapping("/all")
    public ResponseEntity<List<RecommendationResponse>> listAll() {
        return ResponseEntity.ok(recommendationService.listAllForUser(currentUser.id()));
    }

    @PostMapping("/{id}/complete")
    public ResponseEntity<RecommendationResponse> complete(@PathVariable UUID id) {
        return ResponseEntity.ok(recommendationService.markCompleted(id, currentUser.id()));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable UUID id) {
        recommendationService.delete(id, currentUser.id());
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/generate")
    public ResponseEntity<List<RecommendationResponse>> generate() {
        return ResponseEntity.ok(recommendationService.generateFromPerformance(currentUser.id()));
    }
}
