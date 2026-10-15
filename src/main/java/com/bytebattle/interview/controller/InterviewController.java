package com.bytebattle.interview.controller;


import com.bytebattle.interview.dto.*;
import com.bytebattle.interview.service.InterviewService;
import jakarta.validation.Valid;
import com.bytebattle.security.CurrentUser;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/interviews")
public class InterviewController {

    private final InterviewService interviewService;
    private final CurrentUser currentUser;

    public InterviewController(InterviewService interviewService, CurrentUser currentUser) {
        this.interviewService = interviewService;
        this.currentUser = currentUser;
    }

    @PostMapping
    public ResponseEntity<InterviewSessionResponse> start(@RequestBody @Valid StartInterviewRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(interviewService.startInterview(request.withUserId(currentUser.id())));
    }

    @GetMapping("/{id}")
    public ResponseEntity<InterviewSessionResponse> get(@PathVariable UUID id) {
        return ResponseEntity.ok(interviewService.getSession(id, currentUser.id()));
    }

    @GetMapping
    public ResponseEntity<List<InterviewSessionResponse>> listForUser() {
        return ResponseEntity.ok(interviewService.listForUser(currentUser.id()));
    }

    @GetMapping("/{id}/messages")
    public ResponseEntity<List<InterviewMessageResponse>> getMessages(@PathVariable UUID id) {
        // ownership check first: 404 unless the session belongs to the caller
        interviewService.getSession(id, currentUser.id());
        return ResponseEntity.ok(interviewService.getMessages(id));
    }

    @PostMapping("/{id}/messages")
    public ResponseEntity<InterviewMessageResponse> sendMessage(
            @PathVariable UUID id,
            @RequestBody @Valid SendInterviewMessageRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(interviewService.sendMessage(id, currentUser.id(), request));
    }

    @PostMapping("/{id}/complete")
    public ResponseEntity<InterviewResultResponse> complete(@PathVariable UUID id) {
        return ResponseEntity.ok(interviewService.completeInterview(id, currentUser.id()));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable UUID id) {
        interviewService.deleteSession(id, currentUser.id());
        return ResponseEntity.noContent().build();
    }
}
