package com.bytebattle.interview.controller;


import com.bytebattle.interview.dto.*;
import com.bytebattle.interview.service.InterviewService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/interviews")
public class InterviewController {

    private final InterviewService interviewService;

    public InterviewController(InterviewService interviewService) {
        this.interviewService = interviewService;
    }

    @PostMapping
    public ResponseEntity<InterviewSessionResponse> start(@RequestBody @Valid StartInterviewRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(interviewService.startInterview(request));
    }

    @GetMapping("/{id}")
    public ResponseEntity<InterviewSessionResponse> get(@PathVariable UUID id, @RequestParam UUID userId) {
        return ResponseEntity.ok(interviewService.getSession(id, userId));
    }

    @GetMapping
    public ResponseEntity<List<InterviewSessionResponse>> listForUser(@RequestParam UUID userId) {
        return ResponseEntity.ok(interviewService.listForUser(userId));
    }

    @GetMapping("/{id}/messages")
    public ResponseEntity<List<InterviewMessageResponse>> getMessages(@PathVariable UUID id) {
        return ResponseEntity.ok(interviewService.getMessages(id));
    }

    @PostMapping("/{id}/messages")
    public ResponseEntity<InterviewMessageResponse> sendMessage(
            @PathVariable UUID id, @RequestParam UUID userId,
            @RequestBody @Valid SendInterviewMessageRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(interviewService.sendMessage(id, userId, request));
    }

    @PostMapping("/{id}/complete")
    public ResponseEntity<InterviewResultResponse> complete(@PathVariable UUID id, @RequestParam UUID userId) {
        return ResponseEntity.ok(interviewService.completeInterview(id, userId));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable UUID id, @RequestParam UUID userId) {
        interviewService.deleteSession(id, userId);
        return ResponseEntity.noContent().build();
    }
}
