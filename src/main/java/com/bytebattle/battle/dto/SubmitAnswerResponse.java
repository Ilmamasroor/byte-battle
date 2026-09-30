package com.bytebattle.battle.dto;

import lombok.Builder;

@Builder
public record SubmitAnswerResponse(
        Boolean correct,
        Integer pointsEarned,
        Integer remainingLives,
        Integer currentScore,
        Boolean sessionCompleted,
        BattleQuestionResponse nextQuestion   // null if session is complete
) {}