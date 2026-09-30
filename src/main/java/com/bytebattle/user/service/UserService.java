package com.bytebattle.user.service;

import com.bytebattle.security.entity.CurrentUser;
import com.bytebattle.exception.BadRequestException;
import com.bytebattle.exception.ConflictException;
import com.bytebattle.exception.ResourceNotFoundException;
import com.bytebattle.user.dto.ChangePasswordRequest;
import com.bytebattle.user.dto.UpdateUserRequest;
import com.bytebattle.user.dto.UserResponse;
import com.bytebattle.user.entity.User;
import com.bytebattle.user.repository.UserRepository;

import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Locale;

@Service
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final CurrentUser currentUser;

    public UserService(UserRepository userRepository,
                       PasswordEncoder passwordEncoder,
                       CurrentUser currentUser) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.currentUser = currentUser;
    }

    private User getActiveUser(String userId) {
        return userRepository.findByIdAndActiveTrue(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
    }

    // ---- lookups (used by other modules / admin) ----
    @Transactional(readOnly = true)
    public UserResponse getUserById(String id) {
        return UserResponse.fromEntity(userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("User not found")));
    }

    @Transactional(readOnly = true)
    public UserResponse getUserByEmail(String email) {
        return UserResponse.fromEntity(userRepository.findByEmail(email.trim().toLowerCase(Locale.ROOT))
                .orElseThrow(() -> new ResourceNotFoundException("User not found")));
    }

    // ---- self-service ----
    @Transactional(readOnly = true)
    public UserResponse getMyProfile() {
        return UserResponse.fromEntity(getActiveUser(currentUser.id()));
    }

    @Transactional
    public UserResponse updateMyProfile(UpdateUserRequest request) {
        User user = getActiveUser(currentUser.id());

        if (request.getUsername() != null) {
            String name = request.getUsername().trim();
            if (name.length() < 2) {
                throw new BadRequestException("Username must be at least 2 characters");
            }
            user.setName(name);
        }

        if (request.getEmail() != null) {
            String email = request.getEmail().trim().toLowerCase(Locale.ROOT);
            if (!email.equals(user.getEmail())) {
                if (userRepository.existsByEmail(email)) {
                    throw new ConflictException("Email is already registered");
                }
                user.setEmail(email);
            }
        }

        if (request.getProfilePictureUrl() != null) {
            String url = request.getProfilePictureUrl().trim();
            user.setProfilePictureUrl(url.isEmpty() ? null : url);
        }

        return UserResponse.fromEntity(userRepository.save(user));
    }

    @Transactional
    public void changePassword(ChangePasswordRequest request) {
        User user = getActiveUser(currentUser.id());

        if (!passwordEncoder.matches(request.getCurrentPassword(), user.getPasswordHash())) {
            throw new BadRequestException("Current password is incorrect");
        }
        if (passwordEncoder.matches(request.getNewPassword(), user.getPasswordHash())) {
            throw new BadRequestException("New password must be different from the current password");
        }

        user.setPasswordHash(passwordEncoder.encode(request.getNewPassword()));
        userRepository.save(user);
    }

    @Transactional
    public void deactivateMyAccount() {
        deactivateAccount(currentUser.id());
    }

    // ---- account state (internal / admin use only; do NOT expose reactivate to normal users) ----
    @Transactional
    public void deactivateAccount(String userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        user.setActive(false);
        userRepository.save(user);
    }

    @Transactional
    public void reactivateAccount(String userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        user.setActive(true);
        userRepository.save(user);
    }
}