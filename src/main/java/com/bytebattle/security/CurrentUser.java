package com.bytebattle.security;

import com.bytebattle.exception.UnauthorizedException;
import com.bytebattle.user.User;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

import java.util.UUID;

/**
 * Single place that resolves "who is calling" from the Spring Security context.
 * Every controller/service must use this instead of trusting a client-supplied userId.
 */
@Component
public class CurrentUser {

    /** The authenticated user entity, or UnauthorizedException (-> 401). */
    public User get() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        return get(authentication);
    }

    public UUID id() {
        return get().getId();
    }

    public boolean isAdmin() {
        return get().getRole() == User.Role.ADMIN;
    }

    /** Variant for callers that already hold an Authentication (e.g. controller parameter). */
    public User get(Authentication authentication) {
        if (authentication == null
                || !authentication.isAuthenticated()
                || !(authentication.getPrincipal() instanceof CustomUserDetails details)
                || details.getUser() == null
                || details.getUser().getId() == null) {
            throw new UnauthorizedException("Authentication required");
        }
        return details.getUser();
    }

    public UUID id(Authentication authentication) {
        return get(authentication).getId();
    }
}
