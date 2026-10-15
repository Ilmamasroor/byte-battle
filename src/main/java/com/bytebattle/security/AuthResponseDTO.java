package com.bytebattle.security;

import java.util.UUID;

public class AuthResponseDTO {
    private String token;
    private UUID userId;
    private String email;
    private String username;
    private boolean onboardingCompleted;

    public AuthResponseDTO() {
    }

    public AuthResponseDTO(String token, UUID userId, String email, String username) {
        this.token = token;
        this.userId = userId;
        this.email = email;
        this.username = username;
    }

    public AuthResponseDTO(String token, UUID userId, String email, String username,
                           boolean onboardingCompleted) {
        this(token, userId, email, username);
        this.onboardingCompleted = onboardingCompleted;
    }

    public boolean isOnboardingCompleted() {
        return onboardingCompleted;
    }

    public void setOnboardingCompleted(boolean onboardingCompleted) {
        this.onboardingCompleted = onboardingCompleted;
    }

    public String getToken() {
        return token;
    }

    public void setToken(String token) {
        this.token = token;
    }

    public UUID getUserId() {
        return userId;
    }

    public void setUserId(UUID userId) {
        this.userId = userId;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }
}