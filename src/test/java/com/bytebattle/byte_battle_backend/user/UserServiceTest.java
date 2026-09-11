package com.bytebattle.byte_battle_backend.user;

import com.bytebattle.byte_battle_backend.exception.ResourceNotFoundException;
import com.bytebattle.byte_battle_backend.security.CustomUserDetails;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContext;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;


/**
 * Tests for UserService - specifically the "logged in user" operations
 * (get my profile, update profile, change password).
 */
@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @InjectMocks
    private UserService userService;

    private User currentUser;
    private UUID currentUserId;

    @BeforeEach
    void setUp() {
        currentUserId = UUID.randomUUID();
        currentUser = new User();
        currentUser.setId(currentUserId);
        currentUser.setEmail("test@example.com");
        currentUser.setName("testuser");
        currentUser.setPasswordHash("old-hashed-password");

        // Simulate a logged-in user in the security context, the same way
        // JwtAuthFilter does for a real request.
        CustomUserDetails userDetails = new CustomUserDetails(currentUser);
        SecurityContext securityContext = mock(SecurityContext.class);
        lenient().when(securityContext.getAuthentication()).thenReturn(                new UsernamePasswordAuthenticationToken(userDetails, null, userDetails.getAuthorities())
        );
        SecurityContextHolder.setContext(securityContext);
    }

    @Test
    void changePassword_succeedsWithCorrectCurrentPassword() {
        ChangePasswordRequestDTO request = new ChangePasswordRequestDTO();
        request.setCurrentPassword("correct-password");
        request.setNewPassword("new-password-123");

        when(userRepository.findById(currentUserId)).thenReturn(Optional.of(currentUser));
        when(passwordEncoder.matches("correct-password", "old-hashed-password")).thenReturn(true);
        when(passwordEncoder.encode("new-password-123")).thenReturn("new-hashed-password");

        userService.changePassword(request);

        verify(userRepository, times(1)).save(currentUser);
        assertEquals("new-hashed-password", currentUser.getPasswordHash());
    }

    @Test
    void changePassword_throwsWhenCurrentPasswordIsWrong() {
        ChangePasswordRequestDTO request = new ChangePasswordRequestDTO();
        request.setCurrentPassword("wrong-password");
        request.setNewPassword("new-password-123");

        when(userRepository.findById(currentUserId)).thenReturn(Optional.of(currentUser));
        when(passwordEncoder.matches("wrong-password", "old-hashed-password")).thenReturn(false);

        IllegalArgumentException exception = assertThrows(
                IllegalArgumentException.class,
                () -> userService.changePassword(request)
        );

        assertEquals("Current password is incorrect", exception.getMessage());
        verify(userRepository, never()).save(any());
    }

    @Test
    void getMyProfile_throwsWhenUserNotFound() {
        when(userRepository.findById(currentUserId)).thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class, () -> userService.getMyProfile());
    }
    
    @Test
    void getMyProfile_returnsProfileForCurrentUser() {
        when(userRepository.findById(currentUserId)).thenReturn(Optional.of(currentUser));

        UserResponseDTO result = userService.getMyProfile();

        assertNotNull(result);
        assertEquals("test@example.com", result.getEmail());
    }

    @Test
    void updateMyProfile_updatesNameSuccessfully() {
        UpdateUserRequestDTO request = new UpdateUserRequestDTO();
        request.setUsername("newname");

        when(userRepository.findById(currentUserId)).thenReturn(Optional.of(currentUser));
        when(userRepository.save(any(User.class))).thenReturn(currentUser);

        UserResponseDTO result = userService.updateMyProfile(request);

        assertEquals("newname", currentUser.getName());
        verify(userRepository, times(1)).save(currentUser);
    }

    @Test
    void getMyProfile_throwsWhenNoAuthenticatedUser() {
        SecurityContextHolder.clearContext();

        assertThrows(Exception.class, () -> userService.getMyProfile());
    }  
}