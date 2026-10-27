package com.bytebattle.gamification.controller;

import com.bytebattle.gamification.dto.LearnerStatsResponse;
import com.bytebattle.gamification.service.GamificationService;
import com.bytebattle.security.CurrentUser;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/gamification")
public class GamificationController {

    private final GamificationService gamificationService;
    private final CurrentUser currentUser;

    public GamificationController(GamificationService gamificationService, CurrentUser currentUser) {
        this.gamificationService = gamificationService;
        this.currentUser = currentUser;
    }

    @GetMapping("/me")
    public ResponseEntity<LearnerStatsResponse> me() {
        return ResponseEntity.ok(gamificationService.get(currentUser.id()));
    }
}
