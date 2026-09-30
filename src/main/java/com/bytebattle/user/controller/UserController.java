package com.bytebattle.user.controller;


import com.bytebattle.common.ApiResponse;
import com.bytebattle.user.dto.ChangePasswordRequest;
import com.bytebattle.user.dto.UpdateUserRequest;
import com.bytebattle.user.dto.UserResponse;
import com.bytebattle.user.service.UserService;

import jakarta.validation.Valid;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/users")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping("/me")
    public ApiResponse<UserResponse> getMyProfile() {
        return ApiResponse.success(userService.getMyProfile());
    }

    @PutMapping("/me")
    public ApiResponse<UserResponse> updateMyProfile(@Valid @RequestBody UpdateUserRequest request) {
        return ApiResponse.success("Profile updated", userService.updateMyProfile(request));
    }

    @PutMapping("/me/password")
    public ApiResponse<Void> changePassword(@Valid @RequestBody ChangePasswordRequest request) {
        userService.changePassword(request);
        return ApiResponse.success("Password changed successfully", null);
    }

    @DeleteMapping("/me")
    public ApiResponse<Void> deactivateMyAccount() {
        userService.deactivateMyAccount();
        return ApiResponse.success("Account deactivated successfully", null);
    }

    // Admin-only. Other backend modules must call UserService directly, not this endpoint.
    @PreAuthorize("hasRole('ADMIN')")
    @GetMapping("/{id}")
    public ApiResponse<UserResponse> getUserById(@PathVariable String id) {
        return ApiResponse.success(userService.getUserById(id));
    }
}