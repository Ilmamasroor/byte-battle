package com.bytebattle.learner.service;

import com.bytebattle.exception.ResourceNotFoundException;
import com.bytebattle.learner.dto.CreateLearnerProfileRequestDTO;
import com.bytebattle.learner.dto.LearnerProfileResponseDTO;
import com.bytebattle.learner.dto.UpdateLearnerProfileRequestDTO;
import com.bytebattle.learner.entity.LearnerProfile;
import com.bytebattle.learner.repository.LearnerProfileRepository;
import com.bytebattle.security.service.CustomUserDetails;
import com.bytebattle.user.entity.User;
import com.bytebattle.user.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

@Service
@Transactional
public class LearnerProfileService {

    private final LearnerProfileRepository learnerProfileRepository;
    private final UserRepository userRepository;

    public LearnerProfileService(
            LearnerProfileRepository learnerProfileRepository,
            UserRepository userRepository) {

        this.learnerProfileRepository = learnerProfileRepository;
        this.userRepository = userRepository;
    }

    /**
     * Gets the authenticated user's ID from Spring Security.
     *
     * The client does NOT provide this ID.
     */
    private String getCurrentUserId() {

        Authentication authentication =
                SecurityContextHolder
                        .getContext()
                        .getAuthentication();

        if (authentication == null
                || !authentication.isAuthenticated()
                || !(authentication.getPrincipal()
                    instanceof CustomUserDetails userDetails)) {

            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED,
                    "Authentication required"
            );
        }

        return userDetails.getUser().getId();
    }

    /**
     * GET current learner profile.
     */
    @Transactional(readOnly = true)
    public LearnerProfileResponseDTO getMyProfile() {

        String userId = getCurrentUserId();

        LearnerProfile profile =
                learnerProfileRepository
                        .findByUser_Id(userId)
                        .orElseThrow(() ->
                                new ResourceNotFoundException(
                                        "Learner profile not found"
                                )
                        );

        return LearnerProfileResponseDTO.fromEntity(profile);
    }

    /**
     * Create learner profile for authenticated user.
     */
    public LearnerProfileResponseDTO createProfile(
            CreateLearnerProfileRequestDTO request) {

        String userId = getCurrentUserId();

        if (learnerProfileRepository.existsByUser_Id(userId)) {

            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Learner profile already exists"
            );
        }

        User user =
                userRepository.findById(userId)
                        .orElseThrow(() ->
                                new ResourceNotFoundException(
                                        "User not found"
                                )
                        );

        LearnerProfile profile =
                new LearnerProfile();

        profile.setUser(user);
        profile.setExperienceLevel(
                request.getExperienceLevel()
        );
        profile.setPreferredLanguage(
                request.getPreferredLanguage().trim()
        );
        profile.setDailyGoalMinutes(
                request.getDailyGoalMinutes()
        );

        LearnerProfile saved =
                learnerProfileRepository.save(profile);

        return LearnerProfileResponseDTO.fromEntity(saved);
    }

    /**
     * Update authenticated user's own profile.
     */
    public LearnerProfileResponseDTO updateProfile(
            UpdateLearnerProfileRequestDTO request) {

        String userId = getCurrentUserId();

        LearnerProfile profile =
                learnerProfileRepository
                        .findByUser_Id(userId)
                        .orElseThrow(() ->
                                new ResourceNotFoundException(
                                        "Learner profile not found"
                                )
                        );

        if (request.getExperienceLevel() != null) {

            profile.setExperienceLevel(
                    request.getExperienceLevel()
            );
        }

        if (request.getPreferredLanguage() != null) {

            String language =
                    request.getPreferredLanguage().trim();

            if (!language.isEmpty()) {
                profile.setPreferredLanguage(language);
            }
        }

        if (request.getDailyGoalMinutes() != null) {

            profile.setDailyGoalMinutes(
                    request.getDailyGoalMinutes()
            );
        }

        LearnerProfile saved =
                learnerProfileRepository.save(profile);

        return LearnerProfileResponseDTO.fromEntity(saved);
    }
}