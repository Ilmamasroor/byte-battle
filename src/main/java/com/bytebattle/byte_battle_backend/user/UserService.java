package com.bytebattle.byte_battle_backend.user;

import com.bytebattle.byte_battle_backend.exception.ResourceNotFoundException;
import com.bytebattle.byte_battle_backend.security.CustomUserDetails;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public UserService(UserRepository userRepository, PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
    }

    private UUID getCurrentUserId() {
        CustomUserDetails userDetails =
                (CustomUserDetails) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        return userDetails.getUser().getId();
    }

    public UserResponseDTO getUserById(UUID id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + id));
        return UserResponseDTO.fromEntity(user);
    }

    public UserResponseDTO getUserByEmail(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with email: " + email));
        return UserResponseDTO.fromEntity(user);
    }

    // GET /api/users/me
    public UserResponseDTO getMyProfile() {
        return getUserById(getCurrentUserId());
    }

    // PUT /api/users/me
    public UserResponseDTO updateMyProfile(UpdateUserRequestDTO request) {
        UUID userId = getCurrentUserId();
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        if (request.getUsername() != null) {
            user.setName(request.getUsername());
        }

        if (request.getEmail() != null) {
            if (!request.getEmail().equals(user.getEmail())
                    && userRepository.existsByEmail(request.getEmail())) {
                throw new IllegalArgumentException("Email is already registered");
            }
            user.setEmail(request.getEmail());
        }

        User saved = userRepository.save(user);
        return UserResponseDTO.fromEntity(saved);
    }

    // PUT /api/users/me/password
    public void changePassword(ChangePasswordRequestDTO request) {
        UUID userId = getCurrentUserId();
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        if (!passwordEncoder.matches(request.getCurrentPassword(), user.getPasswordHash())) {
            throw new IllegalArgumentException("Current password is incorrect");
        }

        user.setPasswordHash(passwordEncoder.encode(request.getNewPassword()));
        userRepository.save(user);
    }

    // Account state management (per architecture doc - UserService responsibility)
    public void deactivateAccount(UUID userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        user.setActive(false);
        userRepository.save(user);
    }

    public void reactivateAccount(UUID userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        user.setActive(true);
        userRepository.save(user);
    }

    public void deactivateMyAccount() {
        UUID userId = getCurrentUserId();
        deactivateAccount(userId);
    }
    
}