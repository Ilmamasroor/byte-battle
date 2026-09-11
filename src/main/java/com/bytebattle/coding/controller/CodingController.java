package com.bytebattle.coding.controller;


import com.bytebattle.coding.dto.*;
import com.bytebattle.coding.service.CodingService;
import jakarta.validation.Valid;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/coding")
public class CodingController {

    private final CodingService codingService;

    public CodingController(CodingService codingService) {
        this.codingService = codingService;
    }

    @GetMapping("/challenges/{challengeId}")
    public ResponseEntity<CodingChallengeResponse> getChallenge(@PathVariable UUID challengeId) {
        return ResponseEntity.ok(codingService.getChallenge(challengeId));
    }

    @PostMapping("/challenges/{challengeId}/submissions")
    public ResponseEntity<CodeSubmissionResponse> submit(
            @PathVariable UUID challengeId,
            @RequestParam UUID userId,   // TEMPORARY — replace with authenticated principal once JWT is wired in
            @RequestBody @Valid CodeSubmissionRequest request) {
        return ResponseEntity.ok(codingService.submitCode(challengeId, userId, request));
    }

    @GetMapping("/submissions/{submissionId}")
    public ResponseEntity<CodeSubmissionResponse> getSubmission(
            @PathVariable UUID submissionId,
            @RequestParam UUID userId) {   // TEMPORARY — same as above
        return ResponseEntity.ok(codingService.getSubmission(submissionId, userId));
    }
    
    @PostMapping("/challenges")
    public ResponseEntity<CodingChallengeResponse> createChallenge(
            @RequestBody @Valid CreateCodingChallengeRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(codingService.createChallenge(request));
    }

    @PutMapping("/challenges/{challengeId}")
    public ResponseEntity<CodingChallengeResponse> updateChallenge(
            @PathVariable UUID challengeId, @RequestBody UpdateCodingChallengeRequest request) {
        return ResponseEntity.ok(codingService.updateChallenge(challengeId, request));
    }

    @DeleteMapping("/challenges/{challengeId}")
    public ResponseEntity<Void> deleteChallenge(@PathVariable UUID challengeId) {
        codingService.deleteChallenge(challengeId);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/challenges")
    public ResponseEntity<List<CodingChallengeResponse>> listChallenges() {
        return ResponseEntity.ok(codingService.listChallenges());
    }

    @GetMapping("/concepts/{conceptId}/challenges")
    public ResponseEntity<List<CodingChallengeResponse>> listByConcept(@PathVariable UUID conceptId) {
        return ResponseEntity.ok(codingService.listChallengesByConcept(conceptId));
    }
}