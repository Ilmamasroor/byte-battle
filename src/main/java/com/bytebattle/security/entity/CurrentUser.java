package com.bytebattle.security.entity;

import com.bytebattle.security.service.CustomUserDetails;

import org.springframework.security.authentication.AuthenticationCredentialsNotFoundException;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

@Component
public class CurrentUser {

    public CustomUserDetails details() {

        Authentication auth =
                SecurityContextHolder
                        .getContext()
                        .getAuthentication();

        if (auth == null
                || !auth.isAuthenticated()
                || !(auth.getPrincipal() instanceof CustomUserDetails details)) {

            throw new AuthenticationCredentialsNotFoundException(
                    "Not authenticated"
            );
        }

        return details;
    }

    public String id() {
        return details().getUser().getId();
    }
}