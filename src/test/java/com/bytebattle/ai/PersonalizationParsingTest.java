package com.bytebattle.ai;

import com.bytebattle.bytedna.ByteDNA;
import com.bytebattle.ai.dto.personalization.DiagnosisSummaryAiRequest;
import com.bytebattle.ai.dto.personalization.ByteDnaEvolutionRequest;
import com.bytebattle.battle.dto.StartBattleRequest;
import com.bytebattle.interview.dto.StartInterviewRequest;
import com.bytebattle.performance.dto.CreatePerformanceRecordRequest;
import com.bytebattle.recommendation.dto.CreateRecommendationRequest;
import com.bytebattle.learning.dto.StartLearningRequest;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;

import java.lang.reflect.Method;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

class PersonalizationParsingTest {

    private final ObjectMapper mapper = new ObjectMapper();

    @SuppressWarnings("unchecked")
    private <E extends Enum<E>> E parse(Class<E> type, String v, E def) throws Exception {
        Method m = Class.forName("com.bytebattle.ai.service.PersonalizationAiService")
                .getDeclaredMethod("parseEnum", Class.class, String.class, Enum.class);
        m.setAccessible(true);
        return (E) m.invoke(null, type, v, def);
    }

    @Test
    void unknownAiStringsFallBackToDefaultInsteadOfThrowing() throws Exception {
        assertEquals(ByteDNA.TechnicalExperience.BEGINNER,
                parse(ByteDNA.TechnicalExperience.class, "wizard", ByteDNA.TechnicalExperience.BEGINNER));
        assertEquals(ByteDNA.TechnicalExperience.ADVANCED,
                parse(ByteDNA.TechnicalExperience.class, " advanced ", ByteDNA.TechnicalExperience.BEGINNER));
        assertNull(parse(ByteDNA.ExplanationStyle.class, "poetry", null));
        assertEquals(ByteDNA.LearningStyle.INTERVIEW_PREP,
                parse(ByteDNA.LearningStyle.class, "interview-prep", null));
        assertNull(parse(ByteDNA.LearningStyle.class, "", null));
    }

    @Test
    void clientSuppliedUserIdIsIgnoredWhenDeserializingBodies() throws Exception {
        UUID evil = UUID.randomUUID();
        UUID concept = UUID.randomUUID();

        assertNull(mapper.readValue("{\"userId\":\"" + evil + "\"}", StartBattleRequest.class).userId());
        assertNull(mapper.readValue("{\"userId\":\"" + evil + "\",\"conceptId\":\"" + concept
                + "\",\"difficulty\":\"EASY\"}", StartInterviewRequest.class).userId());
        StartLearningRequest l = mapper.readValue(
                "{\"userId\":\"" + evil + "\",\"conceptId\":\"" + concept + "\"}", StartLearningRequest.class);
        assertNull(l.userId());
        assertEquals(concept, l.conceptId());
        assertNull(mapper.readValue("{\"userId\":\"" + evil + "\",\"title\":\"t\"}", CreateRecommendationRequest.class).userId());
        assertNull(mapper.readValue("{\"userId\":\"" + evil + "\",\"score\":1}", CreatePerformanceRecordRequest.class).userId());
    }

    @Test
    void withUserIdOverridesEverywhere() {
        UUID me = UUID.randomUUID();
        UUID evil = UUID.randomUUID();
        DiagnosisSummaryAiRequest req = new DiagnosisSummaryAiRequest(evil, List.of(
                new DiagnosisSummaryAiRequest.DiagnosisActivity(evil, "coding", 1.0, 1, 1, 1, 0, 1, 1, true)));
        DiagnosisSummaryAiRequest bound = req.withUserId(me);
        assertEquals(me, bound.userId());
        assertEquals(me, bound.activities().get(0).userId());

        ByteDnaEvolutionRequest evo = new ByteDnaEvolutionRequest(evil, "t", null, null, null).withUserId(me);
        assertEquals(me, evo.userId());
    }
}
