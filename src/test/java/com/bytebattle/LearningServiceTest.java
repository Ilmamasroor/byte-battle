package com.bytebattle;

import com.bytebattle.learning.dto.CompleteStageRequest;
import com.bytebattle.learning.dto.LearningProgressResponse;
import com.bytebattle.learning.dto.StartLearningRequest;
import com.bytebattle.learning.entity.LearningProgress;
import com.bytebattle.learning.enums.LearningStage;
import com.bytebattle.learning.repository.LearningProgressRepository;
import com.bytebattle.learning.service.LearningService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

class LearningServiceTest {

    @Mock private LearningProgressRepository repository;
    private LearningService service;

    private final UUID userId = UUID.randomUUID();
    private final UUID conceptId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
        service = new LearningService(repository);
    }

    @Test
    void startConcept_createsNewProgress_whenNoneExists() {
        when(repository.findByUserIdAndConceptId(userId, conceptId)).thenReturn(Optional.empty());
        when(repository.save(any())).thenAnswer(inv -> {
            LearningProgress p = inv.getArgument(0);
            p.setId(UUID.randomUUID());
            return p;
        });

        LearningProgressResponse response = service.startConcept(new StartLearningRequest(userId, conceptId));

        assertThat(response.currentStage()).isEqualTo(LearningStage.UNDERSTAND);
        assertThat(response.progressPercentage()).isEqualTo(10);
        assertThat(response.completed()).isFalse();
    }

    @Test
    void startConcept_returnsExisting_whenAlreadyStarted() {
        LearningProgress existing = LearningProgress.builder()
                .id(UUID.randomUUID()).userId(userId).conceptId(conceptId)
                .currentStage(LearningStage.BATTLE).completed(false).progressPercentage(55)
                .build();
        when(repository.findByUserIdAndConceptId(userId, conceptId)).thenReturn(Optional.of(existing));
        when(repository.save(any())).thenReturn(existing);

        LearningProgressResponse response = service.startConcept(new StartLearningRequest(userId, conceptId));

        assertThat(response.currentStage()).isEqualTo(LearningStage.BATTLE);
    }

    @Test
    void completeStage_advancesThroughAllStagesInOrder() {
        LearningProgress progress = LearningProgress.builder()
                .id(UUID.randomUUID()).userId(userId).conceptId(conceptId)
                .currentStage(LearningStage.UNDERSTAND).completed(false).progressPercentage(10)
                .build();

        when(repository.findById(progress.getId())).thenReturn(Optional.of(progress));
        when(repository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        LearningProgressResponse result = service.completeStage(new CompleteStageRequest(progress.getId()));

        assertThat(result.currentStage()).isEqualTo(LearningStage.VISUALIZE);
        assertThat(result.progressPercentage()).isEqualTo(20);
    }

    @Test
    void completeStage_marksCompleted_whenReachingFinalStage() {
        LearningProgress progress = LearningProgress.builder()
                .id(UUID.randomUUID()).userId(userId).conceptId(conceptId)
                .currentStage(LearningStage.IMPROVE).completed(false).progressPercentage(95)
                .build();

        when(repository.findById(progress.getId())).thenReturn(Optional.of(progress));
        when(repository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        LearningProgressResponse result = service.completeStage(new CompleteStageRequest(progress.getId()));

        assertThat(result.currentStage()).isEqualTo(LearningStage.COMPLETED);
        assertThat(result.completed()).isTrue();
        assertThat(result.completedAt()).isNotNull();
    }

    @Test
    void getProgress_throws_whenNotFound() {
        UUID missingId = UUID.randomUUID();
        when(repository.findById(missingId)).thenReturn(Optional.empty());

        org.junit.jupiter.api.Assertions.assertThrows(
                IllegalArgumentException.class, () -> service.getProgress(missingId));
    }
}