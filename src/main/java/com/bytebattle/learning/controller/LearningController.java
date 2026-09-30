package com.bytebattle.learning.controller;

import com.bytebattle.learning.dto.CompleteStageRequest;
import com.bytebattle.learning.dto.LearningProgressResponse;
import com.bytebattle.learning.dto.StartLearningRequest;
import com.bytebattle.learning.service.LearningService;
import com.bytebattle.security.entity.CurrentUser;

import jakarta.validation.Valid;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/learning")
public class LearningController {

    private final LearningService learningService;
    private final CurrentUser currentUser;

    public LearningController(
            LearningService learningService,
            CurrentUser currentUser) {

        this.learningService = learningService;
        this.currentUser = currentUser;
    }

    @PostMapping("/start")
    public ResponseEntity<LearningProgressResponse> start(
            @RequestBody @Valid StartLearningRequest request) {

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(
                        learningService.startConcept(
                                request,
                                currentUser.id()
                        )
                );
    }

    @GetMapping("/progress")
    public ResponseEntity<List<LearningProgressResponse>> myProgress() {

        return ResponseEntity.ok(
                learningService.getAllForUser(
                        currentUser.id()
                )
        );
    }

    @GetMapping("/progress/{progressId}")
    public ResponseEntity<LearningProgressResponse> getProgress(
            @PathVariable UUID progressId) {

        return ResponseEntity.ok(
                learningService.getOwnedProgress(
                        progressId,
                        currentUser.id()
                )
        );
    }

    @PostMapping("/complete-stage")
    public ResponseEntity<LearningProgressResponse> completeStage(
            @RequestBody @Valid CompleteStageRequest request) {

        return ResponseEntity.ok(
                learningService.completeStage(
                        request,
                        currentUser.id()
                )
        );
    }

    @DeleteMapping("/progress/{progressId}")
    public ResponseEntity<Void> delete(
            @PathVariable UUID progressId) {

        learningService.deleteProgress(
                progressId,
                currentUser.id()
        );

        return ResponseEntity.noContent().build();
    }
}