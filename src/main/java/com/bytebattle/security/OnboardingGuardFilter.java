package com.bytebattle.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.util.AntPathMatcher;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Learning endpoints need the baseline Byte DNA and learner profile (the cold-start data). A signed-in learner who
 * has not finished onboarding gets 403 ONBOARDING_REQUIRED. Admins are exempt (they manage content).
 * Created in SecurityConfig, so it only runs inside the security chain.
 */
public class OnboardingGuardFilter extends OncePerRequestFilter {

    public static final String ERROR_MESSAGE = "ONBOARDING_REQUIRED: complete onboarding (POST /api/onboarding) first";

    private static final AntPathMatcher PATHS = new AntPathMatcher();

    /** Gated for every HTTP method. */
    private static final List<String> GATED = List.of(
            "/api/learning/**", "/api/battle-sessions/**", "/api/debugging/**",
            "/api/interviews/**", "/api/visualize/**", "/api/ai/**");
    /** Gated for POST only. */
    private static final List<String> GATED_POST = List.of(
            "/api/battles/*/start", "/api/coding/challenges/*/submissions");
    /** Never gated: the legacy onboarding bridge. */
    private static final List<String> OPEN = List.of("/api/ai/onboarding");

    private final OnboardingStatusProvider statusProvider;
    private final ApiErrorWriter errorWriter;
    /** Onboarding never un-happens, so a positive answer is remembered (saves two queries per request). */
    private final Map<UUID, Boolean> completed = new ConcurrentHashMap<>();

    public OnboardingGuardFilter(OnboardingStatusProvider statusProvider, ApiErrorWriter errorWriter) {
        this.statusProvider = statusProvider;
        this.errorWriter = errorWriter;
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        return !isGated(request.getMethod(), request.getRequestURI());
    }

    static boolean isGated(String method, String path) {
        if (OPEN.stream().anyMatch(p -> PATHS.match(p, path))) {
            return false;
        }
        return GATED.stream().anyMatch(p -> PATHS.match(p, path))
                || ("POST".equalsIgnoreCase(method) && GATED_POST.stream().anyMatch(p -> PATHS.match(p, path)));
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.getPrincipal() instanceof CustomUserDetails details) {
            boolean admin = details.getUser().getRole() == com.bytebattle.user.User.Role.ADMIN;
            UUID userId = details.getUser().getId();
            if (!admin && !completed.containsKey(userId)) {
                if (!statusProvider.isOnboardingCompleted(userId)) {
                    errorWriter.write(response, HttpServletResponse.SC_FORBIDDEN, ERROR_MESSAGE);
                    return;
                }
                completed.put(userId, Boolean.TRUE);
            }
        }
        chain.doFilter(request, response);
    }
}
