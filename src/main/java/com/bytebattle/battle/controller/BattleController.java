package com.bytebattle.battle.controller;

import com.bytebattle.battle.dto.BattleQuestionResponse;
import com.bytebattle.battle.dto.BattleResponse;
import com.bytebattle.battle.dto.CreateBattleQuestionRequest;
import com.bytebattle.battle.dto.CreateBattleRequest;
import com.bytebattle.battle.dto.StartBattleRequest;
import com.bytebattle.battle.dto.StartBattleResponse;
import com.bytebattle.battle.dto.UpdateBattleRequest;
import com.bytebattle.battle.service.BattleService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/battles")
public class BattleController {

    private final BattleService battleService;

    public BattleController(BattleService battleService) {
        this.battleService = battleService;
    }

    @GetMapping("/{battleId}")
    public ResponseEntity<BattleResponse> getBattle(@PathVariable UUID battleId) {
        return ResponseEntity.ok(battleService.getBattle(battleId));
    }

    @PostMapping("/{battleId}/start")
    public ResponseEntity<StartBattleResponse> startBattle(@PathVariable UUID battleId,
                                                             @Valid @RequestBody StartBattleRequest request) {
        StartBattleResponse response = battleService.startBattle(battleId, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @PostMapping
    public ResponseEntity<BattleResponse> createBattle(@RequestBody @Valid CreateBattleRequest request) {
        BattleResponse response = battleService.createBattle(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping
    public ResponseEntity<List<BattleResponse>> listBattles() {
        return ResponseEntity.ok(battleService.listBattles());
    }

    @PutMapping("/{battleId}")
    public ResponseEntity<BattleResponse> updateBattle(
            @PathVariable UUID battleId, @RequestBody UpdateBattleRequest request) {
        return ResponseEntity.ok(battleService.updateBattle(battleId, request));
    }

    @DeleteMapping("/{battleId}")
    public ResponseEntity<Void> deleteBattle(@PathVariable UUID battleId) {
        battleService.deleteBattle(battleId);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/{battleId}/questions")
    public ResponseEntity<BattleQuestionResponse> addQuestion(
            @PathVariable UUID battleId, @RequestBody @Valid CreateBattleQuestionRequest request) {
        BattleQuestionResponse response = battleService.addQuestion(battleId, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping("/{battleId}/questions")
    public ResponseEntity<List<BattleQuestionResponse>> listQuestions(@PathVariable UUID battleId) {
        return ResponseEntity.ok(battleService.listQuestions(battleId));
    }
}