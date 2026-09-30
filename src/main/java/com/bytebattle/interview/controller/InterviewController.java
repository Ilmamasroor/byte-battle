package com.bytebattle.interview.controller;

import com.bytebattle.interview.dto.InterviewSessionResponse;
import com.bytebattle.interview.dto.StartInterviewRequest;
import com.bytebattle.interview.service.InterviewService;
import com.bytebattle.security.entity.CurrentUser;

import jakarta.validation.Valid;

import lombok.RequiredArgsConstructor;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;



@RestController
@RequestMapping("/api/interviews")
@RequiredArgsConstructor
public class InterviewController {

    private final InterviewService interviewService;
    private final CurrentUser currentUser;

    @PostMapping
    public ResponseEntity<InterviewSessionResponse> start(
            @RequestBody @Valid StartInterviewRequest request) {

        return ResponseEntity.status(HttpStatus.CREATED)
                .body(
                    interviewService.startInterview(
                        request,
                        currentUser.id()
                    )
                );
    }
}