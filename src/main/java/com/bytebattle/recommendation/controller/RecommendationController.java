package com.bytebattle.recommendation.controller;

import com.bytebattle.recommendation.dto.CreateRecommendationRequest;
import com.bytebattle.recommendation.dto.NextBestActionResponse;
import com.bytebattle.recommendation.dto.RecommendationResponse;
import com.bytebattle.recommendation.service.RecommendationService;
import com.bytebattle.security.entity.CurrentUser;

import jakarta.validation.Valid;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import org.springframework.security.access.prepost.PreAuthorize;

import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/recommendations")
public class RecommendationController {

    private final RecommendationService recommendationService;
    private final CurrentUser currentUser;

    public RecommendationController(
            RecommendationService recommendationService,
            CurrentUser currentUser) {

        this.recommendationService = recommendationService;
        this.currentUser = currentUser;
    }

    /*
     * ============================================================
     * ADMIN / INTERNAL CREATE
     * ============================================================
     *
     * Normal learners cannot create arbitrary recommendations.
     */
    @PreAuthorize("hasRole('ADMIN')")
    @PostMapping
    public ResponseEntity<RecommendationResponse> create(
            @Valid @RequestBody CreateRecommendationRequest request) {

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(
                        recommendationService.create(request)
                );
    }

    /*
     * ============================================================
     * ACTIVE RECOMMENDATIONS
     * ============================================================
     *
     * User ID comes from JWT/Spring Security.
     * Client cannot choose another user.
     */
    @GetMapping
    public ResponseEntity<List<RecommendationResponse>> listActive() {

        return ResponseEntity.ok(
                recommendationService.listActiveForUser(
                        currentUser.id()
                )
        );
    }

    /*
     * ============================================================
     * RECOMMENDATION HISTORY
     * ============================================================
     */
    @GetMapping("/all")
    public ResponseEntity<List<RecommendationResponse>> listAll(

            @RequestParam(defaultValue = "0")
            int page,

            @RequestParam(defaultValue = "50")
            int size) {

        return ResponseEntity.ok(
                recommendationService.listAllForUser(
                        currentUser.id(),
                        page,
                        size
                )
        );
    }

    /*
     * ============================================================
     * NEXT BEST ACTION
     * ============================================================
     *
     * Backend decides what the learner should do next.
     * Flutter only displays the result.
     */
    @GetMapping("/next")
    public ResponseEntity<NextBestActionResponse> next() {

        return recommendationService
                .nextBestAction(currentUser.id())
                .map(ResponseEntity::ok)
                .orElseGet(
                        () -> ResponseEntity
                                .noContent()
                                .build()
                );
    }

    /*
     * ============================================================
     * COMPLETE
     * ============================================================
     */
    @PostMapping("/{id}/complete")
    public ResponseEntity<RecommendationResponse> complete(
            @PathVariable UUID id) {

        return ResponseEntity.ok(
                recommendationService.markCompleted(
                        id,
                        currentUser.id()
                )
        );
    }

    /*
     * ============================================================
     * DELETE
     * ============================================================
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(
            @PathVariable UUID id) {

        recommendationService.delete(
                id,
                currentUser.id()
        );

        return ResponseEntity.noContent().build();
    }

    /*
     * ============================================================
     * GENERATE FROM PERFORMANCE
     * ============================================================
     *
     * User ID comes from JWT.
     */
    @PostMapping("/generate")
    public ResponseEntity<List<RecommendationResponse>> generate() {

        return ResponseEntity.ok(
                recommendationService.generateFromPerformance(
                        currentUser.id()
                )
        );
    }
}