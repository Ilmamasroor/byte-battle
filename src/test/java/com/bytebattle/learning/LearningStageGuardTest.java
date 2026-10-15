package com.bytebattle.learning;

import com.bytebattle.learning.dto.CompleteStageRequest;
import com.bytebattle.learning.entity.LearningProgress;
import com.bytebattle.learning.enums.LearningStage;
import com.bytebattle.learning.repository.LearningProgressRepository;
import com.bytebattle.learning.service.LearningService;
import org.junit.jupiter.api.Test;
import org.springframework.web.server.ResponseStatusException;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class LearningStageGuardTest {

    LearningProgressRepository repository = mock(LearningProgressRepository.class);
    LearningService service = new LearningService(repository);
    UUID user = UUID.randomUUID();
    UUID concept = UUID.randomUUID();
    UUID progressId = UUID.randomUUID();

    private LearningProgress at(LearningStage stage) {
        return LearningProgress.builder().id(progressId).userId(user).conceptId(concept)
                .currentStage(stage).completed(false).progressPercentage(10).build();
    }

    @Test
    void learnerCannotSkipAnEvidenceStageByHand() {
        when(repository.findByIdAndUserId(progressId, user)).thenReturn(Optional.of(at(LearningStage.CODE)));

        assertThatThrownBy(() -> service.completeStageForUser(new CompleteStageRequest(progressId), user))
                .isInstanceOf(ResponseStatusException.class)
                .hasMessageContaining("passing result");
        verify(repository, never()).save(any());
    }

    @Test
    void learnerCanCompleteContentStages() {
        when(repository.findByIdAndUserId(progressId, user)).thenReturn(Optional.of(at(LearningStage.RELATE)));
        when(repository.save(any())).thenAnswer(i -> i.getArgument(0));

        assertThat(service.completeStageForUser(new CompleteStageRequest(progressId), user).currentStage())
                .isEqualTo(LearningStage.REMEMBER);
    }

    @Test
    void verifiedResultAdvancesOnlyWhenTheLearnerIsExactlyAtThatStage() {
        when(repository.findByUserIdAndConceptId(user, concept)).thenReturn(Optional.of(at(LearningStage.BATTLE)));
        when(repository.save(any())).thenAnswer(i -> i.getArgument(0));

        assertThat(service.advanceIfAt(user, concept, LearningStage.BATTLE)).isPresent();
        // replaying an earlier stage later must not skip ahead
        when(repository.findByUserIdAndConceptId(user, concept)).thenReturn(Optional.of(at(LearningStage.REMEMBER)));
        assertThat(service.advanceIfAt(user, concept, LearningStage.BATTLE)).isEmpty();
        // not started: nothing to advance
        when(repository.findByUserIdAndConceptId(user, concept)).thenReturn(Optional.empty());
        assertThat(service.advanceIfAt(user, concept, LearningStage.BATTLE)).isEmpty();
    }
}
