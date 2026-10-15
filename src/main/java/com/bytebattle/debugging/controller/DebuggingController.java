package com.bytebattle.debugging.controller;


import com.bytebattle.debugging.dto.DebugExerciseDtos.*;
import com.bytebattle.debugging.dto.DebugRequest;
import com.bytebattle.debugging.dto.DebugResponse;
import com.bytebattle.debugging.service.DebugExerciseService;
import com.bytebattle.debugging.service.DebuggingService;
import jakarta.validation.Valid;
import com.bytebattle.security.CurrentUser;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/debugging")
public class DebuggingController {

    private final DebuggingService debuggingService;
    private final DebugExerciseService exerciseService;

    private final CurrentUser currentUser;

    public DebuggingController(
            DebuggingService debuggingService,
            DebugExerciseService exerciseService,
            CurrentUser currentUser) {
        this.debuggingService = debuggingService;
        this.exerciseService = exerciseService;
        this.currentUser = currentUser;
    }

    @PostMapping("/analyze")
    public ResponseEntity<DebugResponse> analyze(@RequestBody @Valid DebugRequest request) {
        return ResponseEntity.ok(debuggingService.analyze(currentUser.id(), request));
    }

    @GetMapping("/exercises")
    public ResponseEntity<List<ExerciseSummary>> listExercises(@RequestParam(required = false) UUID conceptId) {
        return ResponseEntity.ok(exerciseService.list(conceptId));
    }

    @GetMapping("/exercises/{exerciseId}")
    public ResponseEntity<ExerciseDetail> getExercise(@PathVariable UUID exerciseId) {
        return ResponseEntity.ok(exerciseService.get(exerciseId));
    }

    @PostMapping("/exercises/{exerciseId}/attempts")
    public ResponseEntity<AttemptResponse> attempt(
            @PathVariable UUID exerciseId,
            @RequestBody @Valid AttemptRequest request) {
        return ResponseEntity.ok(exerciseService.attempt(currentUser.id(), exerciseId, request));
    }

    @GetMapping("/exercises/{exerciseId}/hint")
    public ResponseEntity<HintResponse> hint(
            @PathVariable UUID exerciseId,
            @RequestParam(defaultValue = "1") int level) {
        return ResponseEntity.ok(exerciseService.hint(currentUser.id(), exerciseId, level));
    }
}
