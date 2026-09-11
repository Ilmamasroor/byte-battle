package com.bytebattle.byte_battle_backend.security;

import com.bytebattle.byte_battle_backend.common.ApiResponse;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    // POST /api/auth/register
    @PostMapping("/register")
    public ApiResponse<AuthResponseDTO> register(@Valid @RequestBody RegisterRequestDTO request) {
        return ApiResponse.success("User registered successfully", authService.register(request));
    }

    // POST /api/auth/login
    @PostMapping("/login")
    public ApiResponse<AuthResponseDTO> login(@Valid @RequestBody LoginRequestDTO request) {
        return ApiResponse.success("Login successful", authService.login(request));
    }

    // POST /api/auth/forgot-password
    @PostMapping("/forgot-password")
    public ApiResponse<Void> forgotPassword(@Valid @RequestBody ForgotPasswordRequestDTO request) {
        authService.forgotPassword(request);
        return ApiResponse.success("Password reset email sent", null);
    }

    // POST /api/auth/reset-password
    @PostMapping("/reset-password")
    public ApiResponse<Void> resetPassword(@Valid @RequestBody ResetPasswordRequestDTO request) {
        authService.resetPassword(request);
        return ApiResponse.success("Password has been reset successfully", null);
    }
}