package com.bytebattle.performance.controller;

import com.bytebattle.performance.dto.PerformanceResponse;
import com.bytebattle.performance.dto.PerformanceSummaryResponse;
import com.bytebattle.performance.service.PerformanceService;
import com.bytebattle.security.entity.CurrentUser;

import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/performance")
public class PerformanceController {

    private final PerformanceService performanceService;
    private final CurrentUser currentUser;

    public PerformanceController(
            PerformanceService performanceService,
            CurrentUser currentUser) {

        this.performanceService = performanceService;
        this.currentUser = currentUser;
    }

    /**
     * Get the authenticated learner's performance history.
     *
     * User identity comes from the JWT/Spring Security context.
     * The client cannot choose another user.
     */
    @GetMapping
    public ResponseEntity<List<PerformanceResponse>> listForUser(

            @RequestParam(defaultValue = "0")
            int page,

            @RequestParam(defaultValue = "50")
            int size) {

        return ResponseEntity.ok(
                performanceService.listForUser(
                        currentUser.id(),
                        page,
                        size
                )
        );
    }

    /**
     * Get the authenticated learner's performance summary.
     */
    @GetMapping("/summary")
    public ResponseEntity<PerformanceSummaryResponse> getSummary() {

        return ResponseEntity.ok(
                performanceService.getSummary(
                        currentUser.id()
                )
        );
    }

    /**
     * Get performance history for one concept,
     * but only for the authenticated learner.
     */
    @GetMapping("/concepts/{conceptId}")
    public ResponseEntity<List<PerformanceResponse>> listForConcept(

            @PathVariable UUID conceptId,

            @RequestParam(defaultValue = "0")
            int page,

            @RequestParam(defaultValue = "50")
            int size) {

        return ResponseEntity.ok(
                performanceService.listForConcept(
                        currentUser.id(),
                        conceptId,
                        page,
                        size
                )
        );
    }

    /**
     * Get the latest performance record for a concept.
     *
     * Returns 204 when the learner has never attempted
     * the concept.
     */
    @GetMapping("/concepts/{conceptId}/latest")
    public ResponseEntity<PerformanceResponse> latestForConcept(
            @PathVariable UUID conceptId) {

        return performanceService
                .getLatestAttempt(currentUser.id(), conceptId)
                .map(r -> performanceService.getRecord(
                        r.getId(),
                        currentUser.id()
                ))
                .map(ResponseEntity::ok)
                .orElseGet(() ->
                        ResponseEntity.noContent().build()
                );
    }

    /**
     * Get one performance record.
     *
     * Ownership must be checked using the authenticated
     * user's ID.
     */
    @GetMapping("/{recordId}")
    public ResponseEntity<PerformanceResponse> get(
            @PathVariable UUID recordId) {

        return ResponseEntity.ok(
                performanceService.getRecord(
                        recordId,
                        currentUser.id()
                )
        );
    }

    /**
     * Performance evidence is append-only for learners.
     *
     * Only an ADMIN can delete a performance record.
     */
    @PreAuthorize("hasRole('ADMIN')")
    @DeleteMapping("/{recordId}")
    public ResponseEntity<Void> delete(
            @PathVariable UUID recordId) {

        performanceService.deleteRecordAsAdmin(
                recordId
        );

        return ResponseEntity
                .noContent()
                .build();
    }
}