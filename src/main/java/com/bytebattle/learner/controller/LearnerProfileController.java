package com.bytebattle.learner.controller;

import com.bytebattle.learner.dto.CreateLearnerProfileRequestDTO;
import com.bytebattle.learner.dto.LearnerProfileResponseDTO;
import com.bytebattle.learner.dto.UpdateLearnerProfileRequestDTO;
import com.bytebattle.learner.service.LearnerProfileService;

import jakarta.validation.Valid;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import org.springframework.security.access.prepost.PreAuthorize;

import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/learner/profile")
public class LearnerProfileController {

    private final LearnerProfileService learnerProfileService;

    public LearnerProfileController(
            LearnerProfileService learnerProfileService) {

        this.learnerProfileService = learnerProfileService;
    }

    /**
     * Get authenticated user's learner profile.
     */
    @GetMapping
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<LearnerProfileResponseDTO> getMyProfile() {

        return ResponseEntity.ok(
                learnerProfileService.getMyProfile()
        );
    }

    /**
     * Create learner profile for authenticated user.
     */
    @PostMapping
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<LearnerProfileResponseDTO> createProfile(
            @Valid @RequestBody CreateLearnerProfileRequestDTO request) {

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(
                        learnerProfileService.createProfile(request)
                );
    }

    /**
     * Update authenticated user's learner profile.
     */
    @PutMapping
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<LearnerProfileResponseDTO> updateProfile(
            @Valid @RequestBody UpdateLearnerProfileRequestDTO request) {

        return ResponseEntity.ok(
                learnerProfileService.updateProfile(request)
        );
    }
}