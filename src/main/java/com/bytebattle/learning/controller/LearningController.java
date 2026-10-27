package com.bytebattle.learning.controller;

import com.bytebattle.learning.dto.CompleteStageRequest;
import com.bytebattle.learning.dto.LearningProgressResponse;
import com.bytebattle.learning.dto.StartLearningRequest;
import com.bytebattle.learning.service.LearningService;
import com.bytebattle.security.CurrentUser;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

/**
 * Learning-loop progress for the authenticated learner. The learner completes the content stages
 * (Understand, Visualize, Relate, Remember, Improve); the evidence stages (Battle, Code, Debug, Interview)
 * advance only from verified results on the server.
 */
@RestController
@RequestMapping("/api/learning")
public class LearningController {

    private final LearningService learningService;
    private final CurrentUser currentUser;

    public LearningController(LearningService learningService, CurrentUser currentUser) {
        this.learningService = learningService;
        this.currentUser = currentUser;
    }

    @PostMapping("/start")
    public ResponseEntity<LearningProgressResponse> start(@RequestBody @Valid StartLearningRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(learningService.startConcept(request.withUserId(currentUser.id())));
    }

    @GetMapping
    public ResponseEntity<List<LearningProgressResponse>> list() {
        return ResponseEntity.ok(learningService.getAllForUser(currentUser.id()));
    }

    @GetMapping("/{progressId}")
    public ResponseEntity<LearningProgressResponse> get(@PathVariable UUID progressId) {
        return ResponseEntity.ok(learningService.getProgressForUser(progressId, currentUser.id()));
    }

    @PostMapping("/complete-stage")
    public ResponseEntity<LearningProgressResponse> completeStage(@RequestBody @Valid CompleteStageRequest request) {
        return ResponseEntity.ok(learningService.completeStageForUser(request, currentUser.id()));
    }

    @DeleteMapping("/{progressId}")
    public ResponseEntity<Void> delete(@PathVariable UUID progressId) {
        learningService.deleteProgressForUser(progressId, currentUser.id());
        return ResponseEntity.noContent().build();
    }
}
