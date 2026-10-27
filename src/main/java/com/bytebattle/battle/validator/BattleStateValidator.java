package com.bytebattle.battle.validator;

import com.bytebattle.battle.entity.BattleQuestion;
import com.bytebattle.battle.entity.BattleSession;
import com.bytebattle.battle.enums.BattleSessionStatus;
import com.bytebattle.battle.repository.AttemptRepository;
import com.bytebattle.battle.repository.BattleSessionRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

@Component
public class BattleStateValidator {

    private final BattleSessionRepository battleSessionRepository;
    private final AttemptRepository attemptRepository;

    public BattleStateValidator(BattleSessionRepository battleSessionRepository,
                                 AttemptRepository attemptRepository) {
        this.battleSessionRepository = battleSessionRepository;
        this.attemptRepository = attemptRepository;
    }

    /**
     * "Not found" and "not yours" collapse into the same Optional.empty() —
     * one orElseThrow, no branch that could be skipped or misordered.
     */
    public BattleSession requireOwnedSession(UUID sessionId, UUID userId) {
        return battleSessionRepository.findByIdAndUserId(sessionId, userId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND, "Battle session not found"));
    }

    /**
     * Chained .filter() calls instead of nested ifs — each filter is an
     * independent, testable condition; if any fails, Optional is empty
     * and orElseThrow fires. No mutable "isValid" flag anywhere.
     */
    public BattleSession requireActiveSession(BattleSession session) {
        return Optional.of(session)
                .filter(s -> s.getStatus() == BattleSessionStatus.ACTIVE)
                .filter(s -> s.getExpiresAt() == null || s.getExpiresAt().isAfter(Instant.now()))
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.CONFLICT, "Battle session is not active or has expired"));
    }

    public BattleQuestion requireQuestionInBattle(BattleQuestion question, UUID battleId) {
        return Optional.of(question)
                .filter(q -> q.getBattleId().equals(battleId))
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.BAD_REQUEST, "Question does not belong to this battle"));
    }

    /**
     * One-attempt-only enforcement (§17 of the doc). Optional.isPresent()
     * IS the check — no separate "hasAnswered" boolean to keep in sync
     * with the attempts table.
     */
    public void requireNotAlreadyAnswered(UUID sessionId, UUID questionId) {
        attemptRepository.findByBattleSessionIdAndBattleQuestionId(sessionId, questionId)
                .ifPresent(attempt -> {
                    throw new ResponseStatusException(
                            HttpStatus.CONFLICT, "This question has already been answered");
                });
    }
}