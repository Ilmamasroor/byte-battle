package com.bytebattle.performance.service;

import com.bytebattle.exception.ResourceNotFoundException;
import com.bytebattle.performance.dto.CreatePerformanceRecordRequest;
import com.bytebattle.performance.dto.PerformanceResponse;
import com.bytebattle.performance.dto.PerformanceSummaryResponse;
import com.bytebattle.performance.entity.PerformanceRecord;
import com.bytebattle.performance.repository.PerformanceRecordRepository;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Comparator;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
public class PerformanceService {

    private static final double STRONG_ACCURACY_THRESHOLD = 0.8;
    private static final double WEAK_ACCURACY_THRESHOLD = 0.5;
    private static final int MAX_PAGE_SIZE = 100;

    private final PerformanceRecordRepository repository;

    public PerformanceService(PerformanceRecordRepository repository) {
        this.repository = repository;
    }

    // ------------------------------------------------------------------
    // Evidence creation: internal use by Battle / Coding / Debugging /
    // Interview / Learning services. No public endpoint calls this.
    // ------------------------------------------------------------------

    /**
     * Idempotent when sourceId is set: the same (user, activityType, sourceId) returns the
     * existing record. A truly concurrent duplicate is rejected by the uk_perf_source
     * constraint and surfaces as 409 via the global handler.
     */
    @Transactional
    public PerformanceResponse createRecord(CreatePerformanceRecordRequest request) {
        validate(request);

        if (request.sourceId() != null) {
            Optional<PerformanceRecord> existing = repository.findByUserIdAndActivityTypeAndSourceId(
                    request.userId(), request.activityType(), request.sourceId());
            if (existing.isPresent()) {
                return toResponse(existing.get());
            }
        }

        PerformanceRecord record = repository.save(PerformanceRecord.builder()
                .userId(request.userId())
                .conceptId(request.conceptId())
                .activityType(request.activityType())
                .score(request.score())
                .accuracy(request.accuracy())
                .timeSpentSeconds(request.timeSpentSeconds())
                .attemptCount(request.attemptCount())
                .success(request.success())
                .hintsUsed(request.hintsUsed() == null ? 0 : request.hintsUsed())
                .testCasesPassed(request.testCasesPassed())
                .testCasesTotal(request.testCasesTotal())
                .sourceId(request.sourceId())
                .build());
        return toResponse(record);
    }

    // ------------------------------------------------------------------
    // Reads (always scoped by the caller's userId)
    // ------------------------------------------------------------------

    @Transactional(readOnly = true)
    public PerformanceResponse getRecord(UUID recordId, String userId) {
        return repository.findByIdAndUserId(recordId, userId)
                .map(this::toResponse)
                .orElseThrow(() -> new ResourceNotFoundException("Record not found"));
    }

    @Transactional(readOnly = true)
    public List<PerformanceResponse> listForUser(String userId, int page, int size) {
        return repository.findByUserIdOrderByCreatedAtDesc(userId, pageable(page, size)).stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<PerformanceResponse> listForConcept(String userId, UUID conceptId, int page, int size) {
        return repository.findByUserIdAndConceptIdOrderByCreatedAtDesc(userId, conceptId, pageable(page, size))
                .stream()
                .map(this::toResponse)
                .toList();
    }

    /** Newest-first evidence for the AI diagnosis step. */
    @Transactional(readOnly = true)
    public List<PerformanceResponse> recentForUser(String userId, int limit) {
        return listForUser(userId, 0, limit);
    }

    @Transactional(readOnly = true)
    public Optional<PerformanceRecord> getLatestAttempt(String userId, UUID conceptId) {
        return repository.findFirstByUserIdAndConceptIdOrderByCreatedAtDesc(userId, conceptId);
    }

    /** @deprecated user ids are Strings; kept only so older callers still compile. */
    @Deprecated
    @Transactional(readOnly = true)
    public Optional<PerformanceRecord> getLatestAttempt(UUID userId, UUID conceptId) {
        return getLatestAttempt(userId.toString(), conceptId);
    }

    // ------------------------------------------------------------------
    // Summary: accuracy, score, success rate, weak/strong concepts.
    // All aggregation happens in PostgreSQL.
    // ------------------------------------------------------------------

    @Transactional(readOnly = true)
    public PerformanceSummaryResponse getSummary(String userId) {
        PerformanceRecordRepository.OverallStats stats = repository.getOverallStats(userId);

        long total = stats.getTotalActivities() == null ? 0L : stats.getTotalActivities();
        long successes = stats.getSuccessCount() == null ? 0L : stats.getSuccessCount();

        List<PerformanceRecordRepository.ConceptAccuracy> byConcept = repository.getAccuracyByConcept(userId);

        List<String> weak = byConcept.stream()
                .filter(c -> c.getAverageAccuracy() != null && c.getAverageAccuracy() < WEAK_ACCURACY_THRESHOLD)
                .sorted(Comparator.comparingDouble(PerformanceRecordRepository.ConceptAccuracy::getAverageAccuracy))
                .map(c -> c.getConceptId().toString())
                .toList();

        List<String> strong = byConcept.stream()
                .filter(c -> c.getAverageAccuracy() != null && c.getAverageAccuracy() >= STRONG_ACCURACY_THRESHOLD)
                .sorted(Comparator.comparingDouble(PerformanceRecordRepository.ConceptAccuracy::getAverageAccuracy)
                        .reversed())
                .map(c -> c.getConceptId().toString())
                .toList();

        return PerformanceSummaryResponse.builder()
                .averageAccuracy(stats.getAverageAccuracy() == null ? 0.0 : stats.getAverageAccuracy())
                .averageScore(stats.getAverageScore() == null ? 0.0 : stats.getAverageScore())
                .successRate(total == 0 ? 0.0 : (double) successes / total)
                .totalActivities((int) total)
                .weakConcepts(weak)
                .strongConcepts(strong)
                .totalHintsUsed(stats.getTotalHintsUsed() == null ? 0 : stats.getTotalHintsUsed().intValue())
                .totalTimeSpentSeconds(stats.getTotalTimeSpentSeconds() == null ? 0L : stats.getTotalTimeSpentSeconds())
                .build();
    }

    // ------------------------------------------------------------------
    // Admin only. Learners cannot delete their own evidence.
    // ------------------------------------------------------------------

    @Transactional
    public void deleteRecordAsAdmin(UUID recordId) {
        PerformanceRecord record = repository.findById(recordId)
                .orElseThrow(() -> new ResourceNotFoundException("Record not found"));
        repository.delete(record);
    }

    // ------------------------------------------------------------------
    // helpers
    // ------------------------------------------------------------------

    private Pageable pageable(int page, int size) {
        return PageRequest.of(Math.max(page, 0), Math.min(Math.max(size, 1), MAX_PAGE_SIZE));
    }

    // Internal callers are trusted, but bad evidence corrupts the whole learner model, so reject it.
    private void validate(CreatePerformanceRecordRequest r) {
        if (r.userId() == null || r.conceptId() == null || r.activityType() == null
                || r.score() == null || r.accuracy() == null || r.timeSpentSeconds() == null
                || r.attemptCount() == null || r.success() == null) {
            throw new IllegalArgumentException("Performance record is missing a required field");
        }
        if (r.accuracy() < 0.0 || r.accuracy() > 1.0) {
            throw new IllegalArgumentException("accuracy must be between 0.0 and 1.0");
        }
        if (r.score() < 0 || r.timeSpentSeconds() < 0) {
            throw new IllegalArgumentException("score and timeSpentSeconds must not be negative");
        }
        if (r.attemptCount() < 1) {
            throw new IllegalArgumentException("attemptCount must be at least 1");
        }
        if (r.hintsUsed() != null && r.hintsUsed() < 0) {
            throw new IllegalArgumentException("hintsUsed must not be negative");
        }
        if (r.testCasesPassed() != null && r.testCasesTotal() != null
                && (r.testCasesPassed() < 0 || r.testCasesPassed() > r.testCasesTotal())) {
            throw new IllegalArgumentException("testCasesPassed must be between 0 and testCasesTotal");
        }
    }

    private PerformanceResponse toResponse(PerformanceRecord r) {
        return PerformanceResponse.builder()
                .id(r.getId()).userId(r.getUserId()).conceptId(r.getConceptId())
                .activityType(r.getActivityType()).score(r.getScore()).accuracy(r.getAccuracy())
                .timeSpentSeconds(r.getTimeSpentSeconds()).attemptCount(r.getAttemptCount())
                .success(r.getSuccess()).hintsUsed(r.getHintsUsed())
                .testCasesPassed(r.getTestCasesPassed()).testCasesTotal(r.getTestCasesTotal())
                .createdAt(r.getCreatedAt())
                .build();
    }
<<<<<<< HEAD

    public Optional<PerformanceRecord> getLatestAttempt(UUID userId, UUID conceptId) {
        return repository.findTopByUserIdAndConceptIdOrderByCreatedAtDesc(
                userId,
                conceptId);
    }
    
    
}
=======
}
>>>>>>> a2ff2d8 (Update backend)
