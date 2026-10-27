package com.bytebattle.performance.controller;

import com.bytebattle.performance.dto.*;
import com.bytebattle.performance.service.PerformanceService;
import jakarta.validation.Valid;
import com.bytebattle.security.CurrentUser;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/performance")
public class PerformanceController {

    private final PerformanceService performanceService;
    private final CurrentUser currentUser;

    public PerformanceController(PerformanceService performanceService, CurrentUser currentUser) {
        this.performanceService = performanceService;
        this.currentUser = currentUser;
    }

    @PostMapping
    public ResponseEntity<PerformanceResponse> create(@RequestBody @Valid CreatePerformanceRecordRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(performanceService.createRecord(request.withUserId(currentUser.id())));
    }

    @GetMapping("/{recordId}")
    public ResponseEntity<PerformanceResponse> get(
            @PathVariable UUID recordId) {
        return ResponseEntity.ok(performanceService.getRecord(recordId, currentUser.id()));
    }

    @GetMapping
    public ResponseEntity<List<PerformanceResponse>> listForUser() {
        return ResponseEntity.ok(performanceService.listForUser(currentUser.id()));
    }

    @GetMapping("/concepts/{conceptId}")
    public ResponseEntity<List<PerformanceResponse>> listForConcept(
            @PathVariable UUID conceptId) {
        return ResponseEntity.ok(performanceService.listForConcept(currentUser.id(), conceptId));
    }

    @DeleteMapping("/{recordId}")
    public ResponseEntity<Void> delete(@PathVariable UUID recordId) {
        performanceService.deleteRecord(recordId, currentUser.id());
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/summary")
    public ResponseEntity<PerformanceSummaryResponse> getSummary() {
        return ResponseEntity.ok(performanceService.getSummary(currentUser.id()));
    }
}