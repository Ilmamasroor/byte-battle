package com.bytebattle.onboarding;

import com.bytebattle.ai.client.PersonalizationAiClient;
import com.bytebattle.ai.dto.personalization.ByteDnaAiResponse;
import com.bytebattle.ai.dto.personalization.OnboardingAiRequest;
import com.bytebattle.ai.exception.AiServiceException;
import com.bytebattle.bytedna.ByteDNA;
import com.bytebattle.bytedna.ByteDNARepository;
import com.bytebattle.exception.BadRequestException;
import com.bytebattle.learner.LearnerProfileRepository;
import com.bytebattle.onboarding.OnboardingResponses.Result;
import com.bytebattle.security.OnboardingStatusProvider;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class OnboardingServiceTest {

    PersonalizationAiClient ai = mock(PersonalizationAiClient.class);
    OnboardingStore store = mock(OnboardingStore.class);
    OnboardingQuestionnaire questionnaire = mock(OnboardingQuestionnaire.class);
    OnboardingStatusProvider status = mock(OnboardingStatusProvider.class);
    LearnerProfileRepository profiles = mock(LearnerProfileRepository.class);
    ByteDNARepository dnas = mock(ByteDNARepository.class);
    OnboardingService service;
    final UUID user = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        service = new OnboardingService(ai, store, questionnaire, status, profiles, dnas);
        when(questionnaire.topicSlugs()).thenReturn(Set.of("multithreading", "dsa", "dbms"));
    }

    private OnboardingRequest request(List<String> interests, List<String> confident, List<String> difficult) {
        return new OnboardingRequest(ByteDNA.TechnicalExperience.BEGINNER, " java ", " Campus placements ",
                ByteDNA.LearningStyle.CONCEPTUAL_DEPTH, ByteDNA.ExplanationStyle.DIRECT,
                interests, 30, confident, difficult);
    }

    private static ByteDnaAiResponse aiBaseline(UUID u) {
        return new ByteDnaAiResponse(u, "BEGINNER", "Campus placements", List.of("cricket"), "JAVA",
                new ByteDnaAiResponse.LearningPreferences("CONCEPTUAL_DEPTH"),
                new ByteDnaAiResponse.ExplanationPreferences("DIRECT"), List.of(), List.of(), List.of(), Map.of(), Map.of());
    }

    @Test
    void answersBecomeTheBaselineAndTheSelfAssessmentIsKept() {
        when(ai.onboard(any())).thenReturn(aiBaseline(user));

        Result r = service.complete(user, request(List.of(" Cricket ", "cricket", "Gaming"), List.of("dsa"), List.of("multithreading")));

        ArgumentCaptor<OnboardingAiRequest> sent = ArgumentCaptor.forClass(OnboardingAiRequest.class);
        verify(ai).onboard(sent.capture());
        assertThat(sent.getValue().preferredLanguage()).isEqualTo("JAVA");
        assertThat(sent.getValue().careerGoal()).isEqualTo("Campus placements");
        assertThat(sent.getValue().interests()).containsExactly("cricket", "gaming"); // trimmed, de-duplicated

        ArgumentCaptor<ByteDnaAiResponse> saved = ArgumentCaptor.forClass(ByteDnaAiResponse.class);
        verify(store).persist(any(), any(), saved.capture());
        assertThat(saved.getValue().confidenceAreas()).containsExactly("dsa");
        assertThat(saved.getValue().difficultyAreas()).containsExactly("multithreading");
        assertThat(r.completed()).isTrue();
        assertThat(r.dailyGoalMinutes()).isEqualTo(30);
    }

    @Test
    void anAiOutageNeverBlocksOnboarding() {
        when(ai.onboard(any())).thenThrow(new AiServiceException("AI_UNAVAILABLE", 0, "down"));

        Result r = service.complete(user, request(List.of("music"), List.of(), List.of()));

        ArgumentCaptor<ByteDnaAiResponse> saved = ArgumentCaptor.forClass(ByteDnaAiResponse.class);
        verify(store).persist(any(), any(), saved.capture());
        assertThat(saved.getValue().technicalExperience()).isEqualTo("BEGINNER");
        assertThat(saved.getValue().learningPreferences().learningStyle()).isEqualTo("CONCEPTUAL_DEPTH");
        assertThat(saved.getValue().explanationPreferences().explanationStyle()).isEqualTo("DIRECT");
        assertThat(saved.getValue().interests()).containsExactly("music");
        assertThat(r.completed()).isTrue();
    }

    @Test
    void unknownTopicsAreRejectedBeforeAnythingIsSaved() {
        assertThatThrownBy(() -> service.complete(user, request(List.of(), List.of("astrology"), List.of())))
                .isInstanceOf(BadRequestException.class).hasMessageContaining("astrology");
        verifyNoInteractions(ai, store);
    }

    @Test
    void aTopicCannotBeBothConfidentAndDifficult() {
        assertThatThrownBy(() -> service.complete(user, request(List.of(), List.of("dsa"), List.of("dsa"))))
                .isInstanceOf(BadRequestException.class);
        verifyNoInteractions(store);
    }

    @Test
    void statusReportsBothHalves() {
        when(status.isOnboardingCompleted(user)).thenReturn(false);
        when(profiles.existsByUser_Id(user)).thenReturn(true);
        when(dnas.existsByUser_Id(user)).thenReturn(false);

        var s = service.status(user);

        assertThat(s.completed()).isFalse();
        assertThat(s.hasLearnerProfile()).isTrue();
        assertThat(s.hasByteDna()).isFalse();
    }
}
