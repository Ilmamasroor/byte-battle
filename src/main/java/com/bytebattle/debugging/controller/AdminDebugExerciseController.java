package com.bytebattle.debugging.controller;

import com.bytebattle.debugging.dto.DebugExerciseDtos.*;
import com.bytebattle.debugging.service.DebugExerciseService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

/** ADMIN-only CRUD (guarded by SecurityConfig: /api/admin/**). Responses include solution code and hidden tests. */
@RestController
@RequestMapping("/api/admin/debugging/exercises")
public class AdminDebugExerciseController {

    private final DebugExerciseService service;

    public AdminDebugExerciseController(DebugExerciseService service) {
        this.service = service;
    }

    @GetMapping
    public ResponseEntity<List<AdminExerciseResponse>> list() {
        return ResponseEntity.ok(service.adminList());
    }

    @GetMapping("/{id}")
    public ResponseEntity<AdminExerciseResponse> get(@PathVariable UUID id) {
        return ResponseEntity.ok(service.adminGet(id));
    }

    @PostMapping
    public ResponseEntity<AdminExerciseResponse> create(@RequestBody @Valid AdminExerciseRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.adminCreate(request));
    }

    @PutMapping("/{id}")
    public ResponseEntity<AdminExerciseResponse> update(
            @PathVariable UUID id, @RequestBody AdminExerciseUpdate update) {
        return ResponseEntity.ok(service.adminUpdate(id, update));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable UUID id) {
        service.adminDelete(id);
        return ResponseEntity.noContent().build();
    }
}
