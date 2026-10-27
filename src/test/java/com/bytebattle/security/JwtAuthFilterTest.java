package com.bytebattle.security;

import com.bytebattle.user.User;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockFilterChain;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UsernameNotFoundException;

import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

class JwtAuthFilterTest {

    private final JwtUtil jwtUtil = new JwtUtil(JwtUtilTest.SECRET, 60_000L);
    private final CustomUserDetailsService userDetailsService = mock(CustomUserDetailsService.class);
    private JwtAuthFilter filter;

    @BeforeEach
    void setUp() {
        ObjectMapper mapper = new ObjectMapper().registerModule(new JavaTimeModule());
        filter = new JwtAuthFilter(jwtUtil, userDetailsService,
                new RestAuthenticationEntryPoint(new ApiErrorWriter(mapper)));
        SecurityContextHolder.clearContext();
    }

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    private User user(boolean active) {
        User u = new User();
        u.setId(UUID.randomUUID());
        u.setEmail("a@b.c");
        u.setName("a");
        u.setPasswordHash("x");
        u.setRole(User.Role.USER);
        u.setActive(active);
        return u;
    }

    private MockHttpServletResponse run(String authHeader, MockFilterChain chain) throws Exception {
        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/api/users/me");
        request.setRequestURI("/api/users/me");
        if (authHeader != null) {
            request.addHeader("Authorization", authHeader);
        }
        MockHttpServletResponse response = new MockHttpServletResponse();
        filter.doFilter(request, response, chain);
        return response;
    }

    @Test
    void noHeaderPassesThroughUnauthenticated() throws Exception {
        MockFilterChain chain = new MockFilterChain();
        MockHttpServletResponse response = run(null, chain);

        assertEquals(200, response.getStatus());
        assertNotNull(chain.getRequest());
        assertNull(SecurityContextHolder.getContext().getAuthentication());
    }

    @Test
    void validTokenAuthenticatesUser() throws Exception {
        User u = user(true);
        when(userDetailsService.loadUserByUsername("a@b.c")).thenReturn(new CustomUserDetails(u));
        MockFilterChain chain = new MockFilterChain();

        run("Bearer " + jwtUtil.generateToken("a@b.c"), chain);

        assertNotNull(chain.getRequest());
        assertEquals(u.getId(), new CurrentUser().id());
    }

    @Test
    void garbageTokenGives401NotException() throws Exception {
        MockFilterChain chain = new MockFilterChain();
        MockHttpServletResponse response = run("Bearer not-a-jwt", chain);

        assertEquals(401, response.getStatus());
        assertNull(chain.getRequest(), "chain must not continue");
        assertTrue(response.getContentAsString().contains("\"success\":false"));
    }

    @Test
    void expiredTokenGives401() throws Exception {
        JwtUtil shortLived = new JwtUtil(JwtUtilTest.SECRET, 1L);
        String token = shortLived.generateToken("a@b.c");
        Thread.sleep(20);

        MockHttpServletResponse response = run("Bearer " + token, new MockFilterChain());

        assertEquals(401, response.getStatus());
    }

    @Test
    void unknownUserGives401() throws Exception {
        when(userDetailsService.loadUserByUsername(anyString())).thenThrow(new UsernameNotFoundException("nope"));

        MockHttpServletResponse response = run("Bearer " + jwtUtil.generateToken("ghost@b.c"), new MockFilterChain());

        assertEquals(401, response.getStatus());
        assertNull(SecurityContextHolder.getContext().getAuthentication());
    }

    @Test
    void inactiveUserGives401() throws Exception {
        when(userDetailsService.loadUserByUsername("a@b.c")).thenReturn(new CustomUserDetails(user(false)));

        MockHttpServletResponse response = run("Bearer " + jwtUtil.generateToken("a@b.c"), new MockFilterChain());

        assertEquals(401, response.getStatus());
    }

    @Test
    void authEndpointsIgnoreStaleTokens() throws Exception {
        MockHttpServletRequest request = new MockHttpServletRequest("POST", "/api/auth/login");
        request.setRequestURI("/api/auth/login");
        request.addHeader("Authorization", "Bearer stale");
        MockHttpServletResponse response = new MockHttpServletResponse();
        MockFilterChain chain = new MockFilterChain();

        filter.doFilter(request, response, chain);

        assertEquals(200, response.getStatus());
        assertNotNull(chain.getRequest());
    }
}
