package com.bytebattle.ai;

import com.bytebattle.ai.client.AiFeatureClient;
import com.bytebattle.ai.dto.feature.*;
import com.bytebattle.ai.exception.AiServiceException;
import com.bytebattle.ai.service.AiFeatureService;
import com.bytebattle.bytedna.ByteDNARepository;
import com.bytebattle.curriculum.ConceptRepository;
import com.bytebattle.security.CurrentUser;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class AiFeatureFallbackTest {

    private final AiFeatureClient client = mock(AiFeatureClient.class);
    private final AiFeatureService service = new AiFeatureService(
            client, mock(ConceptRepository.class), mock(ByteDNARepository.class), mock(CurrentUser.class));
    private final Map<String, Object> concept = Map.of("name", "Binary Search");

    private AiServiceException down() {
        return new AiServiceException("AI_UNAVAILABLE", 0, "down");
    }

    @Test
    void templatesUseConceptNameAndAreFlagged() {
        when(client.generateBattleHint(any())).thenThrow(down());
        when(client.generateCodingFeedback(any())).thenThrow(down());
        when(client.generateDebuggingHint(any())).thenThrow(down());
        when(client.generateBossBattle(any())).thenThrow(down());
        when(client.generateAiInterviewQuestion(any())).thenThrow(down());

        BattleHintResponse hint = service.generateBattleHint(concept, "Q?", Map.of(), 1);
        assertTrue(hint.fallback());
        assertTrue(hint.hint().hint().contains("Binary Search"));
        assertEquals(1, hint.hint().hintLevel());

        CodingFeedbackResponse fb = service.generateCodingFeedback(concept, Map.of());
        assertTrue(fb.fallback());
        assertTrue(fb.feedback().contains("Binary Search"));

        DebuggingHintResponse dbg = service.generateDebuggingHint(concept, Map.of(), 1);
        assertTrue(dbg.fallback());
        assertTrue(dbg.hint().contains("Binary Search"));

        BossBattleResponse boss = service.generateBossBattle(concept, Map.of());
        assertTrue(boss.fallback());
        assertTrue(boss.scenario().contains("Binary Search"));
        assertFalse(boss.suggestedOptions().isEmpty());

        AiInterviewQuestionResponse q = service.generateAiInterviewQuestion(concept, Map.of(), List.of());
        assertTrue(q.fallback());
        assertTrue(q.question().contains("Binary Search"));
    }

    @Test
    void realResponsesCarryNoFallbackFlagAndRoundTripThroughJson() throws Exception {
        ObjectMapper mapper = new ObjectMapper();
        String json = mapper.writeValueAsString(new CodingFeedbackResponse("good"));
        assertFalse(json.contains("fallback"));
        assertEquals("good", mapper.readValue("{\"feedback\":\"good\"}", CodingFeedbackResponse.class).feedback());
        assertEquals("q", mapper.readValue("{\"question\":\"q\"}", AiInterviewQuestionResponse.class).question());
        assertTrue(mapper.writeValueAsString(
                new DebuggingHintResponse("h", Boolean.TRUE)).contains("\"fallback\":true"));
    }

    @Test
    void conceptNameFallsBackGracefully() {
        assertEquals("this concept", AiFeatureService.conceptName(Map.of()));
        assertEquals("Heaps", AiFeatureService.conceptName(Map.of("conceptName", "Heaps")));
    }
}
