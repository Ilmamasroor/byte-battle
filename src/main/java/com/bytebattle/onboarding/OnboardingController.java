package com.bytebattle.onboarding;

import com.bytebattle.onboarding.OnboardingResponses.Result;
import com.bytebattle.onboarding.OnboardingResponses.Status;
import com.bytebattle.security.CurrentUser;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * The first-run flow: register -> GET questions -> POST answers. Until it is done the learning endpoints
 * answer 403 ONBOARDING_REQUIRED (see OnboardingGuardFilter).
 */
@RestController
@RequestMapping("/api/onboarding")
public class OnboardingController {

    private final OnboardingService onboardingService;
    private final CurrentUser currentUser;

    public OnboardingController(OnboardingService onboardingService, CurrentUser currentUser) {
        this.onboardingService = onboardingService;
        this.currentUser = currentUser;
    }

    @GetMapping("/questions")
    public ResponseEntity<List<OnboardingQuestion>> questions() {
        return ResponseEntity.ok(onboardingService.questions());
    }

    @GetMapping("/status")
    public ResponseEntity<Status> status() {
        return ResponseEntity.ok(onboardingService.status(currentUser.id()));
    }

    @PostMapping
    public ResponseEntity<Result> complete(@RequestBody @Valid OnboardingRequest request) {
        return ResponseEntity.ok(onboardingService.complete(currentUser.id(), request));
    }
}
