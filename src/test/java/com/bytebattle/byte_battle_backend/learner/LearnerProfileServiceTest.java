package com.bytebattle.learner;

import com.bytebattle.security.CustomUserDetails;
import com.bytebattle.user.User;
import com.bytebattle.user.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContext;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class LearnerProfileServiceTest {

    @Mock
    private LearnerProfileRepository learnerProfileRepository;

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private LearnerProfileService learnerProfileService;

    private User currentUser;
    private UUID currentUserId;

    @BeforeEach
    void setUp() {
        currentUserId = UUID.randomUUID();
        currentUser = new User();
        currentUser.setId(currentUserId);
        currentUser.setEmail("test@example.com");
        currentUser.setName("testuser");

        CustomUserDetails userDetails = new CustomUserDetails(currentUser);
        SecurityContext securityContext = mock(SecurityContext.class);
        when(securityContext.getAuthentication()).thenReturn(
                new UsernamePasswordAuthenticationToken(userDetails, null, userDetails.getAuthorities())
        );
        SecurityContextHolder.setContext(securityContext);
    }

    @Test
    void createProfile_succeedsForNewUser() {
        CreateLearnerProfileRequestDTO request = new CreateLearnerProfileRequestDTO();
        request.setExperienceLevel(LearnerProfile.ExperienceLevel.BEGINNER);
        request.setPreferredLanguage("Python");
        request.setDailyGoalMinutes(30);

        when(learnerProfileRepository.existsByUser_Id(currentUserId)).thenReturn(false);
        when(userRepository.findById(currentUserId)).thenReturn(Optional.of(currentUser));
        when(learnerProfileRepository.save(any(LearnerProfile.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

        LearnerProfileResponseDTO result = learnerProfileService.createProfile(request);

        assertNotNull(result);
        assertEquals("Python", result.getPreferredLanguage());
    }

    @Test
    void createProfile_throwsWhenProfileAlreadyExists() {
        CreateLearnerProfileRequestDTO request = new CreateLearnerProfileRequestDTO();

        when(learnerProfileRepository.existsByUser_Id(currentUserId)).thenReturn(true);

        assertThrows(IllegalArgumentException.class,
                () -> learnerProfileService.createProfile(request));
    }

    @Test
    void updateProfile_updatesDailyGoalSuccessfully() {
        LearnerProfile existingProfile = new LearnerProfile();
        existingProfile.setUser(currentUser);
        existingProfile.setExperienceLevel(LearnerProfile.ExperienceLevel.BEGINNER);
        existingProfile.setPreferredLanguage("Python");
        existingProfile.setDailyGoalMinutes(30);

        UpdateLearnerProfileRequestDTO request = new UpdateLearnerProfileRequestDTO();
        request.setDailyGoalMinutes(45);

        when(learnerProfileRepository.findByUser_Id(currentUserId)).thenReturn(Optional.of(existingProfile));
        when(learnerProfileRepository.save(any(LearnerProfile.class))).thenReturn(existingProfile);

        LearnerProfileResponseDTO result = learnerProfileService.updateProfile(request);

        assertEquals(45, result.getDailyGoalMinutes());
    }
}