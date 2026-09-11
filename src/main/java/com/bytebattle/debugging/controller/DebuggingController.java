package com.bytebattle.debugging.controller;


import com.bytebattle.debugging.dto.DebugRequest;
import com.bytebattle.debugging.dto.DebugResponse;
import com.bytebattle.debugging.service.DebuggingService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/debugging")
public class DebuggingController {

    private final DebuggingService debuggingService;

    public DebuggingController(DebuggingService debuggingService) {
        this.debuggingService = debuggingService;
    }

    @PostMapping("/analyze")
    public ResponseEntity<DebugResponse> analyze(@RequestBody @Valid DebugRequest request) {
        return ResponseEntity.ok(debuggingService.analyze(request));
    }
}