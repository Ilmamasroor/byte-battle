package com.bytebattle.security;

import com.bytebattle.bytedna.ByteDNARepository;
import com.bytebattle.learner.LearnerProfileRepository;
import org.springframework.stereotype.Component;

import java.util.UUID;

@Component
public class DefaultOnboardingStatusProvider implements OnboardingStatusProvider {

    private final LearnerProfileRepository learnerProfileRepository;
    private final ByteDNARepository byteDNARepository;

    public DefaultOnboardingStatusProvider(LearnerProfileRepository learnerProfileRepository,
                                           ByteDNARepository byteDNARepository) {
        this.learnerProfileRepository = learnerProfileRepository;
        this.byteDNARepository = byteDNARepository;
    }

    @Override
    public boolean isOnboardingCompleted(UUID userId) {
        return learnerProfileRepository.existsByUser_Id(userId)
                && byteDNARepository.existsByUser_Id(userId);
    }
}
