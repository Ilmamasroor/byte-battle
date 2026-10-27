package com.bytebattle.learning.service;

import com.bytebattle.gamification.service.GamificationService;
import com.bytebattle.learning.enums.LearningStage;
import com.bytebattle.performance.enums.ActivityType;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.UUID;

/**
 * Turns one verified activity result into progression: streak/XP and, on success, the learning-stage
 * transition for that activity. Called only from server-side result handling (battle grading, Judge0
 * results, debug retests, interview scoring), never from a client-controlled endpoint.
 * Best effort: a failure here is logged and never invalidates the learner's result.
 */
@Service
public class ProgressionService {

    private static final Logger log = LoggerFactory.getLogger(ProgressionService.class);

    static final int XP_BATTLE_WIN = 50;
    static final int XP_BOSS_BATTLE_WIN = 100;
    static final int XP_CODING_PASS = 40;
    static final int XP_DEBUGGING_PASS = 30;
    static final int XP_INTERVIEW_PASS = 30;
    /** Showing up and trying still counts for the streak and earns a little XP. */
    static final int XP_ATTEMPT = 5;

    private final GamificationService gamificationService;
    private final LearningService learningService;

    public ProgressionService(GamificationService gamificationService, LearningService learningService) {
        this.gamificationService = gamificationService;
        this.learningService = learningService;
    }

    public void onActivity(UUID userId, UUID conceptId, ActivityType type, boolean success, boolean boss) {
        try {
            int xp = success ? xpFor(type, boss) : XP_ATTEMPT;
            gamificationService.recordActivity(userId, xp);
            if (success) {
                stageFor(type).ifPresent(stage -> learningService.advanceIfAt(userId, conceptId, stage));
            }
        } catch (RuntimeException e) {
            log.warn("Progression update failed for user={} concept={} type={}", userId, conceptId, type, e);
        }
    }

    static int xpFor(ActivityType type, boolean boss) {
        return switch (type) {
            case BATTLE -> boss ? XP_BOSS_BATTLE_WIN : XP_BATTLE_WIN;
            case CODING -> XP_CODING_PASS;
            case DEBUGGING -> XP_DEBUGGING_PASS;
            case INTERVIEW -> XP_INTERVIEW_PASS;
            case LEARNING -> 0;
        };
    }

    static java.util.Optional<LearningStage> stageFor(ActivityType type) {
        return switch (type) {
            case BATTLE -> java.util.Optional.of(LearningStage.BATTLE);
            case CODING -> java.util.Optional.of(LearningStage.CODE);
            case DEBUGGING -> java.util.Optional.of(LearningStage.DEBUG);
            case INTERVIEW -> java.util.Optional.of(LearningStage.INTERVIEW);
            case LEARNING -> java.util.Optional.empty();
        };
    }
}
