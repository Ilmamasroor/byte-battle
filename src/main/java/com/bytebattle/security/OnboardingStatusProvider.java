package com.bytebattle.security;

import java.util.UUID;

/**
 * Tells the auth flow whether a user has finished the personalization onboarding.
 * Definition: a LearnerProfile row AND a ByteDNA row exist for the user.
 */
public interface OnboardingStatusProvider {
    boolean isOnboardingCompleted(UUID userId);
}
