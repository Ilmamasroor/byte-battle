package com.bytebattle.learner;

import com.bytebattle.exception.ResourceNotFoundException;
import com.bytebattle.security.CustomUserDetails;
import com.bytebattle.user.User;
import com.bytebattle.user.UserRepository;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class LearnerProfileService {

    private final LearnerProfileRepository learnerProfileRepository;
    private final UserRepository userRepository;

    public LearnerProfileService(LearnerProfileRepository learnerProfileRepository,
                                  UserRepository userRepository) {
        this.learnerProfileRepository = learnerProfileRepository;
        this.userRepository = userRepository;
    }

    // Reads the logged-in user's ID from the JWT-authenticated security context
    private UUID getCurrentUserId() {
        CustomUserDetails userDetails =
                (CustomUserDetails) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        return userDetails.getUser().getId();
    }

    public LearnerProfileResponseDTO getMyProfile() {
        UUID userId = getCurrentUserId();
        LearnerProfile profile = learnerProfileRepository.findByUser_Id(userId)
                .orElseThrow(() -> new ResourceNotFoundException("Learner profile not found for this user"));
        return LearnerProfileResponseDTO.fromEntity(profile);
    }

    public LearnerProfileResponseDTO createProfile(CreateLearnerProfileRequestDTO request) {
        UUID userId = getCurrentUserId();

        if (learnerProfileRepository.existsByUser_Id(userId)) {
            throw new IllegalArgumentException("Learner profile already exists for this user");
        }

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        LearnerProfile profile = new LearnerProfile();
        profile.setUser(user);
        profile.setExperienceLevel(request.getExperienceLevel());
        profile.setPreferredLanguage(request.getPreferredLanguage());
        profile.setDailyGoalMinutes(request.getDailyGoalMinutes());

        LearnerProfile saved = learnerProfileRepository.save(profile);
        return LearnerProfileResponseDTO.fromEntity(saved);
    }

    public LearnerProfileResponseDTO updateProfile(UpdateLearnerProfileRequestDTO request) {
        UUID userId = getCurrentUserId();
        LearnerProfile profile = learnerProfileRepository.findByUser_Id(userId)
                .orElseThrow(() -> new ResourceNotFoundException("Learner profile not found for this user"));

        if (request.getExperienceLevel() != null) {
            profile.setExperienceLevel(request.getExperienceLevel());
        }
        if (request.getPreferredLanguage() != null) {
            profile.setPreferredLanguage(request.getPreferredLanguage());
        }
        if (request.getDailyGoalMinutes() != null) {
            profile.setDailyGoalMinutes(request.getDailyGoalMinutes());
        }

        LearnerProfile saved = learnerProfileRepository.save(profile);
        return LearnerProfileResponseDTO.fromEntity(saved);
    }
}