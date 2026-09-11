package com.bytebattle.performance.repository;


import com.bytebattle.performance.entity.PerformanceRecord;
import com.bytebattle.performance.enums.ActivityType;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface PerformanceRecordRepository extends JpaRepository<PerformanceRecord, UUID> {

    List<PerformanceRecord> findByUserId(UUID userId);

    List<PerformanceRecord> findByUserIdAndConceptId(UUID userId, UUID conceptId);

    List<PerformanceRecord> findByUserIdAndActivityType(UUID userId, ActivityType activityType);

    Optional<PerformanceRecord> findByIdAndUserId(UUID id, UUID userId);
}