package com.bytebattle.battle.controller;

import com.bytebattle.battle.dto.BattleResultResponse;
import com.bytebattle.battle.dto.SubmitAnswerRequest;
import com.bytebattle.battle.dto.SubmitAnswerResponse;
import com.bytebattle.battle.service.BattleService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.Optional;
import java.util.UUID;

@RestController
@RequestMapping("/api/battle-sessions")
public class AttemptController {

    private final BattleService battleService;

    public AttemptController(BattleService battleService) {
        this.battleService = battleService;
    }

    @PostMapping("/{sessionId}/attempts")
    public ResponseEntity<SubmitAnswerResponse> submitAnswer(@PathVariable UUID sessionId,
                                                               @Valid @RequestBody SubmitAnswerRequest request,
                                                               Authentication authentication) {
        UUID userId = resolveUserId(authentication);
        return ResponseEntity.ok(battleService.submitAnswer(sessionId, userId, request));
    }

    @PostMapping("/{sessionId}/complete")
    public ResponseEntity<BattleResultResponse> completeSession(@PathVariable UUID sessionId,
                                                                  Authentication authentication) {
        UUID userId = resolveUserId(authentication);
        return ResponseEntity.ok(battleService.getResult(sessionId, userId));
    }

    /**
     * Optional.ofNullable(authentication) covers "no token at all";
     * the two .map() calls cover "token present but malformed name."
     * Either failure collapses to the same 401 — one exit path, not two.
     */
    private UUID resolveUserId(Authentication authentication) {
        return Optional.ofNullable(authentication)
                .map(Authentication::getName)
                .map(UUID::fromString)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.UNAUTHORIZED, "Authentication required"));
    }
}