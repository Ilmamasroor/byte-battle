package com.bytebattle.security;

import com.bytebattle.exception.UnauthorizedException;
import com.bytebattle.user.User;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.security.authentication.AnonymousAuthenticationToken;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.AuthorityUtils;
import org.springframework.security.core.context.SecurityContextHolder;

import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

class CurrentUserTest {

    private final CurrentUser currentUser = new CurrentUser();

    @AfterEach
    void clear() {
        SecurityContextHolder.clearContext();
    }

    private User user(User.Role role) {
        User u = new User();
        u.setId(UUID.randomUUID());
        u.setEmail("a@b.c");
        u.setRole(role);
        return u;
    }

    @Test
    void resolvesUserFromCustomUserDetailsPrincipal() {
        User u = user(User.Role.USER);
        CustomUserDetails details = new CustomUserDetails(u);
        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(details, null, details.getAuthorities()));

        assertEquals(u.getId(), currentUser.id());
        assertSame(u, currentUser.get());
        assertFalse(currentUser.isAdmin());
    }

    @Test
    void detectsAdmin() {
        User u = user(User.Role.ADMIN);
        CustomUserDetails details = new CustomUserDetails(u);
        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(details, null, details.getAuthorities()));

        assertTrue(currentUser.isAdmin());
    }

    @Test
    void worksWithExplicitAuthenticationArgument() {
        User u = user(User.Role.USER);
        CustomUserDetails details = new CustomUserDetails(u);
        assertEquals(u.getId(), currentUser.id(
                new UsernamePasswordAuthenticationToken(details, null, details.getAuthorities())));
    }

    @Test
    void throwsUnauthorizedWhenNoAuthentication() {
        assertThrows(UnauthorizedException.class, currentUser::id);
        assertThrows(UnauthorizedException.class, () -> currentUser.get(null));
    }

    @Test
    void throwsUnauthorizedForAnonymousAndForEmailStringPrincipal() {
        SecurityContextHolder.getContext().setAuthentication(new AnonymousAuthenticationToken(
                "key", "anonymousUser", AuthorityUtils.createAuthorityList("ROLE_ANONYMOUS")));
        assertThrows(UnauthorizedException.class, currentUser::id);

        // the old bug: name (an email) is not an identity we can use as a UUID
        SecurityContextHolder.getContext().setAuthentication(new UsernamePasswordAuthenticationToken(
                "someone@example.com", null, AuthorityUtils.createAuthorityList("ROLE_USER")));
        assertThrows(UnauthorizedException.class, currentUser::id);
    }
}
