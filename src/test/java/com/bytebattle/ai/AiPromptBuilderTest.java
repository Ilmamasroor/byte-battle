package com.bytebattle.ai;

import com.bytebattle.ai.dto.AiRequest;
import com.bytebattle.ai.prompt.AiPromptBuilder;
import com.bytebattle.bytedna.ByteDNA;
import com.bytebattle.bytedna.ByteDNARepository;
import com.bytebattle.curriculum.Concept;
import com.bytebattle.curriculum.ConceptRepository;
import com.bytebattle.curriculum.Topic;
import com.bytebattle.exception.ResourceNotFoundException;
import com.bytebattle.performance.dto.PerformanceSummaryResponse;
import com.bytebattle.performance.service.PerformanceService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.when;

/** The AI request must carry the REAL concept and Byte DNA; "UNKNOWN" placeholders made every answer generic. */
@ExtendWith(MockitoExtension.class)
class AiPromptBuilderTest {

    @Mock PerformanceService performanceService;
    @Mock ConceptRepository conceptRepository;
    @Mock ByteDNARepository byteDNARepository;

    AiPromptBuilder builder;
    final UUID userId = UUID.randomUUID();
    final UUID conceptId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        builder = new AiPromptBuilder(performanceService, conceptRepository, byteDNARepository);
    }

    private Concept concept() {
        Topic topic = new Topic();
        topic.setName("Multithreading & Concurrency");
        Concept c = new Concept();
        c.setId(conceptId);
        c.setName("Race Conditions");
        c.setTopic(topic);
        c.setDifficulty(Concept.DifficultyLevel.HARD);
        return c;
    }

    private void stubSummary() {
        when(performanceService.getSummary(userId))
                .thenReturn(new PerformanceSummaryResponse(0.5, 50.0, 0.5, 4, List.of(), List.of()));
    }

    @Test
    void usesTheRealConceptTopicAndDifficulty() {
        when(conceptRepository.findById(conceptId)).thenReturn(Optional.of(concept()));
        when(byteDNARepository.findByUser_Id(userId)).thenReturn(Optional.empty());
        stubSummary();

        AiRequest request = builder.baseRequest("EXPLANATION", userId, conceptId).build();

        assertThat(request.concept().conceptName()).isEqualTo("Race Conditions");
        assertThat(request.concept().topic()).isEqualTo("Multithreading & Concurrency");
        assertThat(request.concept().difficulty()).isEqualTo("HARD");
        assertThat(request.concept().conceptId()).isEqualTo(conceptId);
        assertThat(request.performance().attemptCount()).isEqualTo(4);
    }

    @Test
    void sendsTheLearnersStoredByteDna() {
        ByteDNA dna = new ByteDNA();
        dna.setTechnicalExperience(ByteDNA.TechnicalExperience.INTERMEDIATE);
        dna.setCareerGoal("Backend developer");
        dna.setInterests(List.of("cricket"));
        dna.setPreferredLanguage("JAVA");
        dna.setExplanationPreferences(ByteDNA.ExplanationStyle.STORY);
        dna.setRepeatedMistakes(List.of("shared-state"));
        dna.setTopicAccuracy(Map.of("multithreading", 0.4, "meta", Map.of("attemptCount", 3)));
        when(conceptRepository.findById(conceptId)).thenReturn(Optional.of(concept()));
        when(byteDNARepository.findByUser_Id(userId)).thenReturn(Optional.of(dna));
        stubSummary();

        AiRequest.ByteDnaInfo info = builder.baseRequest("EXPLANATION", userId, conceptId).build().byteDNA();

        assertThat(info.technicalExperience()).isEqualTo("INTERMEDIATE");
        assertThat(info.interests()).containsExactly("cricket");
        assertThat(info.careerGoal()).isEqualTo("Backend developer");
        assertThat(info.explanationPreferences()).containsEntry("style", "STORY");
        assertThat(info.repeatedMistakes()).containsExactly("shared-state");
        // only numeric accuracies survive: the AI contract is Map<String, Double>
        assertThat(info.topicAccuracy()).containsOnlyKeys("multithreading");
    }

    @Test
    void unknownConceptIsA404NotASilentUnknownPrompt() {
        when(conceptRepository.findById(conceptId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> builder.baseRequest("EXPLANATION", userId, conceptId))
                .isInstanceOf(ResourceNotFoundException.class);
    }
}
