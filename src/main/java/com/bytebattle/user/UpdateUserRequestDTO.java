package com.bytebattle.user;

public class UpdateUserRequestDTO {

    // Both optional - only non-null fields get applied
    private String username;
    private String email;
    private String profilePictureUrl;

    public UpdateUserRequestDTO() {
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }
    public String getProfilePictureUrl() {
        return profilePictureUrl;
    }

    public void setProfilePictureUrl(String profilePictureUrl) {
        this.profilePictureUrl = profilePictureUrl;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }
}