package com.bytebattle.battle.controller;

import com.bytebattle.battle.dto.BattleResultResponse;
import com.bytebattle.battle.dto.SubmitAnswerRequest;
import com.bytebattle.battle.dto.SubmitAnswerResponse;
import com.bytebattle.battle.service.BattleService;
import jakarta.validation.Valid;
import com.bytebattle.security.CurrentUser;
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
    private final CurrentUser currentUser;

    public AttemptController(BattleService battleService, CurrentUser currentUser) {
        this.battleService = battleService;
        this.currentUser = currentUser;
    }

    @PostMapping("/{sessionId}/attempts")
    public ResponseEntity<SubmitAnswerResponse> submitAnswer(@PathVariable UUID sessionId,
                                                               @Valid @RequestBody SubmitAnswerRequest request,
                                                               Authentication authentication) {
        UUID userId = currentUser.id(authentication);
        return ResponseEntity.ok(battleService.submitAnswer(sessionId, userId, request));
    }

    @PostMapping("/{sessionId}/complete")
    public ResponseEntity<BattleResultResponse> completeSession(@PathVariable UUID sessionId,
                                                                  Authentication authentication) {
        UUID userId = currentUser.id(authentication);
        return ResponseEntity.ok(battleService.completeSession(sessionId, userId));
    }

}