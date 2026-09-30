package com.bytebattle.coding.controller;

import com.bytebattle.coding.dto.*;
import com.bytebattle.coding.service.CodingService;
import com.bytebattle.security.CurrentUser;

import jakarta.validation.Valid;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.core.Authentication;
import org.springframework.web.server.ResponseStatusException;
import com.bytebattle.security.CustomUserDetails;
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

    // CHANGED: userId comes from the token, not a request param
    @PostMapping("/challenges/{challengeId}/submissions")
    public ResponseEntity<CodeSubmissionResponse> submit(
            @PathVariable UUID challengeId,
<<<<<<< HEAD
            @RequestBody @Valid CodeSubmissionRequest request,
            Authentication authentication) {
        return ResponseEntity.ok(codingService.submitCode(challengeId, resolveUserId(authentication), request));
=======
            @RequestBody @Valid CodeSubmissionRequest request) {
        return ResponseEntity.ok(codingService.submitCode(challengeId, CurrentUser.id(), request));
>>>>>>> a2ff2d8 (Update backend)
    }

    // CHANGED: userId comes from the token
    @GetMapping("/submissions/{submissionId}")
<<<<<<< HEAD
    public ResponseEntity<CodeSubmissionResponse> getSubmission(
            @PathVariable UUID submissionId,
            Authentication authentication) {
        return ResponseEntity.ok(codingService.getSubmission(submissionId, resolveUserId(authentication)));
    }
    
    private UUID resolveUserId(Authentication authentication) {
    if (authentication == null || authentication.getPrincipal() == null) {
        throw new ResponseStatusException(
                HttpStatus.UNAUTHORIZED,
                "Authentication required"
        );
    }

    if (!(authentication.getPrincipal() instanceof CustomUserDetails userDetails)) {
        throw new ResponseStatusException(
                HttpStatus.UNAUTHORIZED,
                "Invalid authenticated user"
        );
    }

    return userDetails.getUser().getId();
}

=======
    public ResponseEntity<CodeSubmissionResponse> getSubmission(@PathVariable UUID submissionId) {
        return ResponseEntity.ok(codingService.getSubmission(submissionId, CurrentUser.id()));
    }

    // CHANGED: admin only
    @PreAuthorize("hasRole('ADMIN')")
>>>>>>> a2ff2d8 (Update backend)
    @PostMapping("/challenges")
    public ResponseEntity<CodingChallengeResponse> createChallenge(
            @RequestBody @Valid CreateCodingChallengeRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(codingService.createChallenge(request));
    }

    // CHANGED: admin only
    @PreAuthorize("hasRole('ADMIN')")
    @PutMapping("/challenges/{challengeId}")
    public ResponseEntity<CodingChallengeResponse> updateChallenge(
            @PathVariable UUID challengeId, @RequestBody UpdateCodingChallengeRequest request) {
        return ResponseEntity.ok(codingService.updateChallenge(challengeId, request));
    }

    // CHANGED: admin only
    @PreAuthorize("hasRole('ADMIN')")
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
