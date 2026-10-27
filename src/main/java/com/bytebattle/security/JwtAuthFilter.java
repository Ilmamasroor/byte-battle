package com.bytebattle.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

/**
 * Authenticates "Authorization: Bearer ..." requests. A request that presents a token which is
 * invalid, expired, for an unknown user, or for an inactive user is answered with 401 right here
 * (never a 500). Requests without any bearer token pass through unauthenticated and are rejected
 * later by the authorization rules if the route requires authentication. Not a @Component on
 * purpose: it is created in SecurityConfig so it only runs inside the security filter chain.
 */
public class JwtAuthFilter extends OncePerRequestFilter {

    private static final Logger log = LoggerFactory.getLogger(JwtAuthFilter.class);

    private final JwtUtil jwtUtil;
    private final CustomUserDetailsService userDetailsService;
    private final AuthenticationEntryPoint entryPoint;

    public JwtAuthFilter(JwtUtil jwtUtil, CustomUserDetailsService userDetailsService,
                         AuthenticationEntryPoint entryPoint) {
        this.jwtUtil = jwtUtil;
        this.userDetailsService = userDetailsService;
        this.entryPoint = entryPoint;
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        // login/register/forgot-password must work even if the client still holds a stale token
        return request.getRequestURI().startsWith("/api/auth/");
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {

        String authHeader = request.getHeader("Authorization");
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            filterChain.doFilter(request, response);
            return;
        }

        String token = authHeader.substring(7).trim();
        try {
            String email = jwtUtil.extractEmail(token);
            if (email == null || !jwtUtil.isTokenValid(token, email)) {
                throw new BadCredentialsException("Invalid token");
            }

            if (SecurityContextHolder.getContext().getAuthentication() == null) {
                UserDetails userDetails = userDetailsService.loadUserByUsername(email);
                if (!userDetails.isEnabled()) {
                    throw new BadCredentialsException("Account is inactive");
                }
                UsernamePasswordAuthenticationToken authToken =
                        new UsernamePasswordAuthenticationToken(userDetails, null, userDetails.getAuthorities());
                authToken.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
                SecurityContextHolder.getContext().setAuthentication(authToken);
            }
        } catch (AuthenticationException e) {
            reject(request, response, e);
            return;
        } catch (RuntimeException e) {
            // JwtException (malformed/expired/bad signature), IllegalArgumentException, ...
            log.debug("Rejecting request with invalid bearer token: {}", e.getClass().getSimpleName());
            reject(request, response, new BadCredentialsException("Invalid token", e));
            return;
        }

        filterChain.doFilter(request, response);
    }

    private void reject(HttpServletRequest request, HttpServletResponse response,
                        AuthenticationException e) throws IOException, ServletException {
        SecurityContextHolder.clearContext();
        entryPoint.commence(request, response, e);
    }
}
