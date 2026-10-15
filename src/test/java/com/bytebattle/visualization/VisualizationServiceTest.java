package com.bytebattle.visualization;

import com.bytebattle.ai.client.AiVisualizationClient;
import com.bytebattle.ai.exception.AiServiceException;
import com.bytebattle.debugging.entity.DebugExercise;
import com.bytebattle.debugging.repository.DebugExerciseRepository;
import com.bytebattle.exception.ResourceNotFoundException;
import com.bytebattle.visualization.VisualizationDtos.*;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.anyMap;
import static org.mockito.Mockito.*;

class VisualizationServiceTest {

    AiVisualizationClient client = mock(AiVisualizationClient.class);
    DebugExerciseRepository exercises = mock(DebugExerciseRepository.class);
    VisualizationService service;
    final JsonNode result = new ObjectMapper().createObjectNode().put("confidence", "high");

    @BeforeEach
    void setUp() {
        service = new VisualizationService(client, exercises);
        when(client.visualize(anyMap())).thenReturn(result);
    }

    @Test
    void defaultsToAutoModeAndNeverSpendsLlmTokensUnlessAsked() {
        service.visualize(new VisualizeRequest("class A {}", null, null, null));

        ArgumentCaptor<Map<String, Object>> body = ArgumentCaptor.forClass(Map.class);
        verify(client).visualize(body.capture());
        assertThat(body.getValue()).containsEntry("mode", "auto").containsEntry("useLlm", false)
                .containsEntry("language", "java").doesNotContainKey("concept");
    }

    @Test
    void sameInputIsServedFromTheCacheButADifferentModeIsNot() {
        VisualizeRequest req = new VisualizeRequest("class A {}", Mode.RACE, "race", false);

        service.visualize(req);
        service.visualize(req);
        verify(client, times(1)).visualize(anyMap());

        service.visualize(new VisualizeRequest("class A {}", Mode.SAFE, "race", false));
        verify(client, times(2)).visualize(anyMap());
    }

    @Test
    void failuresAreNotCached() {
        when(client.visualize(anyMap()))
                .thenThrow(new AiServiceException("AI_UNAVAILABLE", 0, "down"))
                .thenReturn(result);
        VisualizeRequest req = new VisualizeRequest("class B {}", Mode.AUTO, null, false);

        assertThatThrownBy(() -> service.visualize(req)).isInstanceOf(AiServiceException.class);
        assertThat(service.visualize(req)).isSameAs(result);
    }

    @Test
    void conceptDemoVisualizesTheBuggyCodeOnly() {
        UUID concept = UUID.randomUUID();
        DebugExercise e = new DebugExercise();
        e.setId(UUID.randomUUID());
        e.setTitle("The Vanishing Increments");
        e.setBugCategory("RACE_CONDITION");
        e.setBuggyCode("class Buggy {}");
        e.setSolutionCode("class Solution {}");
        when(exercises.findByConceptIdOrderByCreatedAtAsc(concept)).thenReturn(List.of(e));

        ConceptVisualization v = service.forConcept(concept);

        assertThat(v.title()).isEqualTo("The Vanishing Increments");
        assertThat(v.visualization()).isSameAs(result);
        ArgumentCaptor<Map<String, Object>> body = ArgumentCaptor.forClass(Map.class);
        verify(client).visualize(body.capture());
        assertThat(body.getValue().get("code")).isEqualTo("class Buggy {}"); // never the solution
    }

    @Test
    void conceptWithoutADemoIs404() {
        UUID concept = UUID.randomUUID();
        when(exercises.findByConceptIdOrderByCreatedAtAsc(concept)).thenReturn(List.of());

        assertThatThrownBy(() -> service.forConcept(concept)).isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    void cacheIsBounded() {
        for (int i = 0; i < VisualizationService.CACHE_SIZE + 20; i++) {
            service.visualize(new VisualizeRequest("class C" + i + " {}", Mode.AUTO, null, false));
        }
        verify(client, times(VisualizationService.CACHE_SIZE + 20)).visualize(anyMap());
        service.visualize(new VisualizeRequest("class C0 {}", Mode.AUTO, null, false)); // evicted -> recomputed
        verify(client, times(VisualizationService.CACHE_SIZE + 21)).visualize(anyMap());
    }
}
