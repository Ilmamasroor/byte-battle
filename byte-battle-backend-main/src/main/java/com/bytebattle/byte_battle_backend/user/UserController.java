package com.bytebattle.byte_battle_backend.user;

import com.bytebattle.byte_battle_backend.common.ApiResponse;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/users")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    // GET /api/users/me -> get the logged-in user's own profile
    @GetMapping("/me")
    public ApiResponse<UserResponseDTO> getMyProfile() {
        return ApiResponse.success(userService.getMyProfile());
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

    // GET /api/users/{id} -> kept for internal/cross-module lookups (e.g. by Developer 2)
    @GetMapping("/{id}")
    public ApiResponse<UserResponseDTO> getUserById(@PathVariable UUID id) {
        return ApiResponse.success(userService.getUserById(id));
    }

 // DELETE /api/users/me -> permanently delete the logged-in user's account
 @DeleteMapping("/me")
 public ApiResponse<Void> deleteMyAccount() {
     userService.deleteMyAccount();
     return ApiResponse.success("Account deleted successfully", null);
 }
}