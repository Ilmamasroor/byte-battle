package com.bytebattle.performance.controller;

import com.bytebattle.performance.dto.*;
import com.bytebattle.performance.service.PerformanceService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/performance")
public class PerformanceController {

    private final PerformanceService performanceService;

    public PerformanceController(PerformanceService performanceService) {
        this.performanceService = performanceService;
    }

    @PostMapping
    public ResponseEntity<PerformanceResponse> create(@RequestBody @Valid CreatePerformanceRecordRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(performanceService.createRecord(request));
    }

    @GetMapping("/{recordId}")
    public ResponseEntity<PerformanceResponse> get(
            @PathVariable UUID recordId, @RequestParam UUID userId) {
        return ResponseEntity.ok(performanceService.getRecord(recordId, userId));
    }

    @GetMapping
    public ResponseEntity<List<PerformanceResponse>> listForUser(@RequestParam UUID userId) {
        return ResponseEntity.ok(performanceService.listForUser(userId));
    }

    @GetMapping("/concepts/{conceptId}")
    public ResponseEntity<List<PerformanceResponse>> listForConcept(
            @PathVariable UUID conceptId, @RequestParam UUID userId) {
        return ResponseEntity.ok(performanceService.listForConcept(userId, conceptId));
    }

    @DeleteMapping("/{recordId}")
    public ResponseEntity<Void> delete(@PathVariable UUID recordId, @RequestParam UUID userId) {
        performanceService.deleteRecord(recordId, userId);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/summary")
    public ResponseEntity<PerformanceSummaryResponse> getSummary(@RequestParam UUID userId) {
        return ResponseEntity.ok(performanceService.getSummary(userId));
    }
}