package com.bytebattle.security;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class OnboardingGuardFilterTest {

    @Test
    void learningEndpointsAreGatedForEveryMethod() {
        for (String path : new String[] {
                "/api/learning/start", "/api/learning", "/api/battle-sessions/abc/attempts", "/api/debugging/exercises",
                "/api/interviews", "/api/interviews/x/messages", "/api/visualize", "/api/visualize/concepts/x",
                "/api/ai/explanation", "/api/ai/analogy"}) {
            assertThat(OnboardingGuardFilter.isGated("GET", path)).as("GET " + path).isTrue();
            assertThat(OnboardingGuardFilter.isGated("POST", path)).as("POST " + path).isTrue();
        }
    }

    @Test
    void startingABattleOrSubmittingCodeIsGatedButBrowsingThemIsNot() {
        assertThat(OnboardingGuardFilter.isGated("POST", "/api/battles/123/start")).isTrue();
        assertThat(OnboardingGuardFilter.isGated("POST", "/api/coding/challenges/123/submissions")).isTrue();
        assertThat(OnboardingGuardFilter.isGated("GET", "/api/battles")).isFalse();
        assertThat(OnboardingGuardFilter.isGated("GET", "/api/battles/123/questions")).isFalse();
        assertThat(OnboardingGuardFilter.isGated("GET", "/api/coding/challenges")).isFalse();
        assertThat(OnboardingGuardFilter.isGated("GET", "/api/coding/challenges/123")).isFalse();
    }

    @Test
    void theOnboardingFlowItselfAndAccountEndpointsAreNeverGated() {
        for (String path : new String[] {
                "/api/onboarding", "/api/onboarding/questions", "/api/onboarding/status", "/api/ai/onboarding",
                "/api/users/me", "/api/learner-profile", "/api/byte-dna", "/api/curriculum/domains",
                "/api/gamification/me", "/api/performance/summary", "/api/recommendations"}) {
            assertThat(OnboardingGuardFilter.isGated("POST", path)).as(path).isFalse();
            assertThat(OnboardingGuardFilter.isGated("GET", path)).as(path).isFalse();
        }
    }
}
