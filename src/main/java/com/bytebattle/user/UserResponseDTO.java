package com.bytebattle.user;

import java.time.Instant;
import java.util.UUID;

public class UserResponseDTO {
    private UUID id;
    private String email;
    private String username; // maps to User.name internally; kept as "username" in the API for compatibility
    private User.Role role;
    private Instant createdAt;

    public UserResponseDTO() {
    }

    public UserResponseDTO(UUID id, String email, String username, User.Role role, Instant createdAt) {
        this.id = id;
        this.email = email;
        this.username = username;
        this.role = role;
        this.createdAt = createdAt;
    }

    public static UserResponseDTO fromEntity(User user) {
        return new UserResponseDTO(
                user.getId(),
                user.getEmail(),
                user.getName(),
                user.getRole(),
                user.getCreatedAt()
        );
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }

    public User.Role getRole() { return role; }
    public void setRole(User.Role role) { this.role = role; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}