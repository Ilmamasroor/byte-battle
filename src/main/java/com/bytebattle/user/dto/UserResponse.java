package com.bytebattle.user.dto;


import java.time.Instant;

import com.bytebattle.user.entity.User;

public class UserResponse {
    private String id;
    private String email;
    private String username; // maps to User.name; kept as "username" in the API
    private String profilePictureUrl;
    private User.Role role;
    private Instant createdAt;

    public UserResponse() {}

    public UserResponse(String id, String email, String username,
                           String profilePictureUrl, User.Role role, Instant createdAt) {
        this.id = id;
        this.email = email;
        this.username = username;
        this.profilePictureUrl = profilePictureUrl;
        this.role = role;
        this.createdAt = createdAt;
    }

    public static UserResponse fromEntity(User user) {
        return new UserResponse(
                user.getId(),
                user.getEmail(),
                user.getName(),
                user.getProfilePictureUrl(),
                user.getRole(),
                user.getCreatedAt());
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }
    public String getProfilePictureUrl() { return profilePictureUrl; }
    public void setProfilePictureUrl(String profilePictureUrl) { this.profilePictureUrl = profilePictureUrl; }
    public User.Role getRole() { return role; }
    public void setRole(User.Role role) { this.role = role; }
    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}