package com.bytebattle.battle.controller;

import com.bytebattle.battle.dto.BattleResultResponse;
import com.bytebattle.battle.dto.SubmitAnswerRequest;
import com.bytebattle.battle.dto.SubmitAnswerResponse;
import com.bytebattle.battle.service.BattleService;
import com.bytebattle.security.CurrentUser;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

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
                                                               @Valid @RequestBody SubmitAnswerRequest request) {
        return ResponseEntity.ok(battleService.submitAnswer(sessionId, CurrentUser.id(), request));
    }

    @PostMapping("/{sessionId}/complete")
    public ResponseEntity<BattleResultResponse> completeSession(@PathVariable UUID sessionId) {
        return ResponseEntity.ok(battleService.getResult(sessionId, CurrentUser.id()));
    }
}