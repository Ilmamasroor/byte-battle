package com.bytebattle.user.dto;


import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public class UpdateUserRequest {

    // All optional: null = "leave unchanged"
    @Size(min = 2, max = 100, message = "Username must be 2-100 characters")
    private String username;

    @Email(message = "Invalid email format")
    @Size(max = 254, message = "Email is too long")
    private String email;

    // only http(s) URLs; empty string clears the picture
    @Pattern(regexp = "^(https?://\\S+)?$", message = "Profile picture must be an http(s) URL")
    @Size(max = 500, message = "Profile picture URL is too long")
    private String profilePictureUrl;

    public UpdateUserRequest() {}

    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    public String getProfilePictureUrl() { return profilePictureUrl; }
    public void setProfilePictureUrl(String profilePictureUrl) { this.profilePictureUrl = profilePictureUrl; }
}