package com.bytebattle.user;

import com.bytebattle.common.ApiResponse;
import com.bytebattle.exception.ForbiddenException;
import com.bytebattle.security.CurrentUser;
import com.bytebattle.security.OnboardingStatusProvider;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/users")
public class UserController {

    private final UserService userService;
    private final CurrentUser currentUser;
    private final OnboardingStatusProvider onboardingStatusProvider;

    public UserController(UserService userService, CurrentUser currentUser,
                          OnboardingStatusProvider onboardingStatusProvider) {
        this.userService = userService;
        this.currentUser = currentUser;
        this.onboardingStatusProvider = onboardingStatusProvider;
    }

    // GET /api/users/me -> get the logged-in user's own profile
    @GetMapping("/me")
    public ApiResponse<UserResponseDTO> getMyProfile() {
        UserResponseDTO profile = userService.getMyProfile();
        profile.setOnboardingCompleted(onboardingStatusProvider.isOnboardingCompleted(profile.getId()));
        return ApiResponse.success(profile);
    }

    // PUT /api/users/me -> update the logged-in user's own profile
    @PutMapping("/me")
    public ApiResponse<UserResponseDTO> updateMyProfile(@Valid @RequestBody UpdateUserRequestDTO request) {
        return ApiResponse.success("Profile updated", userService.updateMyProfile(request));
    }

    // PUT /api/users/me/password -> change the logged-in user's password
    @PutMapping("/me/password")
    public ApiResponse<Void> changePassword(@Valid @RequestBody ChangePasswordRequestDTO request) {
        userService.changePassword(request);
        return ApiResponse.success("Password changed successfully", null);
    }

    // GET /api/users/{id} -> ADMIN may look up anyone; everyone else only themselves
    @GetMapping("/{id}")
    public ApiResponse<UserResponseDTO> getUserById(@PathVariable UUID id) {
        User caller = currentUser.get();
        if (caller.getRole() != User.Role.ADMIN && !caller.getId().equals(id)) {
            throw new ForbiddenException("You are not allowed to view this user");
        }
        return ApiResponse.success(userService.getUserById(id));
    }

    // DELETE /api/users/me -> deactivates (soft-deletes) the logged-in user's account
    @DeleteMapping("/me")
    public ApiResponse<Void> deactivateMyAccount() {
        userService.deactivateMyAccount();
        return ApiResponse.success("Account deactivated successfully", null);
    }
}