package com.bytebattle.byte_battle_backend.user;

import java.time.LocalDateTime;
import java.util.UUID;

public class UserResponseDTO {
    private UUID id;
    private String email;
    private String username;
    private User.Role role;
    private LocalDateTime createdAt;
    

    public UserResponseDTO() {
    }

    public UserResponseDTO(UUID id, String email, String username, User.Role role, LocalDateTime createdAt, String profilePictureUrl) {
        this.id = id;
        this.email = email;
        this.username = username;
        this.role = role;
        this.createdAt = createdAt;
        
    }
    public static UserResponseDTO fromEntity(User user) 
    { return new UserResponseDTO( user.getId(), user.getEmail(), user.getUsername(), user.getRole(), user.getCreatedAt() ); }
    // Converts an Entity -> safe DTO (password never included)
    public UserResponseDTO(UUID id, String email, String username, User.Role role, LocalDateTime createdAt) {
        this.id = id;
        this.email = email;
        this.username = username;
        this.role = role;
        this.createdAt = createdAt;
    }
    // ===== Getters and Setters =====
    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
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
    
    

    public User.Role getRole() {
        return role;
    }

    public void setRole(User.Role role) {
        this.role = role;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}