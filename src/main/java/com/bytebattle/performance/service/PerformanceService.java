package com.bytebattle.performance.service;


import com.bytebattle.performance.dto.*;
import com.bytebattle.performance.entity.PerformanceRecord;
import com.bytebattle.performance.repository.PerformanceRecordRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class PerformanceService {

    private static final double STRONG_ACCURACY_THRESHOLD = 0.8;
    private static final double WEAK_ACCURACY_THRESHOLD = 0.5;

    private final PerformanceRecordRepository repository;

    public PerformanceService(PerformanceRecordRepository repository) {
        this.repository = repository;
    }

    public PerformanceResponse createRecord(CreatePerformanceRecordRequest request) {
        PerformanceRecord record = repository.save(PerformanceRecord.builder()
                .userId(request.userId())
                .conceptId(request.conceptId())
                .activityType(request.activityType())
                .score(request.score())
                .accuracy(request.accuracy())
                .timeSpentSeconds(request.timeSpentSeconds())
                .attemptCount(request.attemptCount())
                .success(request.success())
                .build());
        return toResponse(record);
    }

    public PerformanceResponse getRecord(UUID recordId, UUID userId) {
        return repository.findByIdAndUserId(recordId, userId)
                .map(this::toResponse)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Record not found"));
    }

    public List<PerformanceResponse> listForUser(UUID userId) {
        return repository.findByUserId(userId).stream()
                .map(this::toResponse)
                .toList();
    }

    public List<PerformanceResponse> listForConcept(UUID userId, UUID conceptId) {
        return repository.findByUserIdAndConceptId(userId, conceptId).stream()
                .map(this::toResponse)
                .toList();
    }

    public void deleteRecord(UUID recordId, UUID userId) {
        repository.findByIdAndUserId(recordId, userId)
                .ifPresentOrElse(
                        repository::delete,
                        () -> { throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Record not found"); }
                );
    }

    /** Custom aggregation — doc §28: accuracy, speed, success rate, weak/strong concepts. */
    public PerformanceSummaryResponse getSummary(UUID userId) {
        List<PerformanceRecord> records = repository.findByUserId(userId);

        double avgAccuracy = records.stream()
                .mapToDouble(PerformanceRecord::getAccuracy)
                .average()
                .orElse(0.0);

        double avgScore = records.stream()
                .mapToInt(PerformanceRecord::getScore)
                .average()
                .orElse(0.0);

        double successRate = records.stream()
                .mapToInt(r -> Boolean.TRUE.equals(r.getSuccess()) ? 1 : 0)
                .average()
                .orElse(0.0);

        Map<UUID, Double> avgAccuracyByConcept = records.stream()
                .collect(Collectors.groupingBy(
                        PerformanceRecord::getConceptId,
                        Collectors.averagingDouble(PerformanceRecord::getAccuracy)));

        List<String> weak = avgAccuracyByConcept.entrySet().stream()
                .filter(e -> e.getValue() < WEAK_ACCURACY_THRESHOLD)
                .sorted(Map.Entry.comparingByValue())
                .map(e -> e.getKey().toString())
                .toList();

        List<String> strong = avgAccuracyByConcept.entrySet().stream()
                .filter(e -> e.getValue() >= STRONG_ACCURACY_THRESHOLD)
                .sorted(Map.Entry.<UUID, Double>comparingByValue().reversed())
                .map(e -> e.getKey().toString())
                .toList();

        return PerformanceSummaryResponse.builder()
                .averageAccuracy(avgAccuracy)
                .averageScore(avgScore)
                .successRate(successRate)
                .totalActivities(records.size())
                .weakConcepts(weak)
                .strongConcepts(strong)
                .build();
    }

    private PerformanceResponse toResponse(PerformanceRecord r) {
        return PerformanceResponse.builder()
                .id(r.getId()).userId(r.getUserId()).conceptId(r.getConceptId())
                .activityType(r.getActivityType()).score(r.getScore()).accuracy(r.getAccuracy())
                .timeSpentSeconds(r.getTimeSpentSeconds()).attemptCount(r.getAttemptCount())
                .success(r.getSuccess()).createdAt(r.getCreatedAt())
                .build();
    }

	public Optional<PerformanceRecord> getLatestAttempt(UUID userId, UUID conceptId) {
		// TODO Auto-generated method stub
		return null;
	}
    
    
}
