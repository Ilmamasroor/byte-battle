package com.bytebattle;


import com.bytebattle.performance.dto.PerformanceSummaryResponse;
import com.bytebattle.performance.entity.PerformanceRecord;
import com.bytebattle.performance.enums.ActivityType;
import com.bytebattle.performance.repository.PerformanceRecordRepository;
import com.bytebattle.performance.service.PerformanceService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

class PerformanceServiceTest {

    @Mock private PerformanceRecordRepository repository;
    private PerformanceService service;
    private final UUID userId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
        service = new PerformanceService(repository);
    }

    @Test
    void getSummary_returnsZeroDefaults_whenNoRecordsExist() {
        when(repository.findByUserId(userId)).thenReturn(List.of());

        PerformanceSummaryResponse summary = service.getSummary(userId);

        assertThat(summary.totalActivities()).isZero();
        assertThat(summary.averageAccuracy()).isZero();
        assertThat(summary.weakConcepts()).isEmpty();
        assertThat(summary.strongConcepts()).isEmpty();
    }

    @Test
    void getSummary_classifiesWeakAndStrongConceptsCorrectly() {
        UUID weakConcept = UUID.randomUUID();
        UUID strongConcept = UUID.randomUUID();

        List<PerformanceRecord> records = List.of(
                record(weakConcept, 0.3, 40, false),
                record(strongConcept, 0.9, 90, true)
        );
        when(repository.findByUserId(userId)).thenReturn(records);

        PerformanceSummaryResponse summary = service.getSummary(userId);

        assertThat(summary.weakConcepts()).containsExactly(weakConcept.toString());
        assertThat(summary.strongConcepts()).containsExactly(strongConcept.toString());
        assertThat(summary.totalActivities()).isEqualTo(2);
    }

    private PerformanceRecord record(UUID conceptId, double accuracy, int score, boolean success) {
        return PerformanceRecord.builder()
                .id(UUID.randomUUID()).userId(userId).conceptId(conceptId)
                .activityType(ActivityType.BATTLE).score(score).accuracy(accuracy)
                .timeSpentSeconds(30).attemptCount(1).success(success)
                .build();
    }
}