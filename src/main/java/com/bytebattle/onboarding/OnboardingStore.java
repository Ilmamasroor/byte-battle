package com.bytebattle.onboarding;

import com.bytebattle.ai.dto.personalization.ByteDnaAiResponse;
import com.bytebattle.ai.service.PersonalizationAiService;
import com.bytebattle.learner.LearnerProfile;
import com.bytebattle.learner.LearnerProfileRepository;
import com.bytebattle.user.User;
import com.bytebattle.user.UserRepository;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

/** Writes the learner profile and the baseline Byte DNA in ONE transaction: onboarding is all or nothing. */
@Component
public class OnboardingStore {

    private final LearnerProfileRepository learnerProfileRepository;
    private final UserRepository userRepository;
    private final PersonalizationAiService personalizationAiService;

    public OnboardingStore(LearnerProfileRepository learnerProfileRepository,
                           UserRepository userRepository,
                           PersonalizationAiService personalizationAiService) {
        this.learnerProfileRepository = learnerProfileRepository;
        this.userRepository = userRepository;
        this.personalizationAiService = personalizationAiService;
    }

    @Transactional
    public void persist(UUID userId, OnboardingRequest request, ByteDnaAiResponse byteDna) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new com.bytebattle.exception.ResourceNotFoundException("User not found"));

        LearnerProfile profile = learnerProfileRepository.findByUser_Id(userId).orElseGet(() -> {
            LearnerProfile p = new LearnerProfile();
            p.setUser(user);
            return p;
        });
        profile.setExperienceLevel(LearnerProfile.ExperienceLevel.valueOf(request.technicalExperience().name()));
        profile.setPreferredLanguage(request.preferredLanguage().trim().toUpperCase(java.util.Locale.ROOT));
        profile.setDailyGoalMinutes(request.dailyGoalMinutes());
        learnerProfileRepository.save(profile);

        personalizationAiService.saveOnboarding(userId, byteDna);
    }
}
