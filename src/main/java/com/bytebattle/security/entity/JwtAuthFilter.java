package com.bytebattle.security.entity;

import com.bytebattle.security.service.CustomUserDetailsService;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;

import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

@Component
public class JwtAuthFilter extends OncePerRequestFilter {

    private static final Logger log =
            LoggerFactory.getLogger(JwtAuthFilter.class);

    private final JwtUtil jwtUtil;
    private final CustomUserDetailsService userDetailsService;

    public JwtAuthFilter(
            JwtUtil jwtUtil,
            CustomUserDetailsService userDetailsService) {

        this.jwtUtil = jwtUtil;
        this.userDetailsService = userDetailsService;
    }

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain)
            throws ServletException, IOException {

        String authHeader = request.getHeader("Authorization");

        // No JWT → continue request normally.
        // SecurityConfig will decide whether authentication is required.
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            filterChain.doFilter(request, response);
            return;
        }

        String token = authHeader.substring(7);

        try {

            // JWT subject contains the user's ID.
            String userId = jwtUtil.extractUserId(token);

            if (userId != null
                    && SecurityContextHolder.getContext().getAuthentication() == null) {

                /*
                 * Load the current user from the database.
                 *
                 * This is important:
                 * We do NOT trust user information from the request.
                 */
                UserDetails userDetails =
                        userDetailsService.loadUserById(userId);

                /*
                 * Deactivated users are treated as unauthenticated.
                 */
                if (userDetails.isEnabled()) {

                    UsernamePasswordAuthenticationToken authToken =
                            new UsernamePasswordAuthenticationToken(
                                    userDetails,
                                    null,
                                    userDetails.getAuthorities()
                            );

                    authToken.setDetails(
                            new WebAuthenticationDetailsSource()
                                    .buildDetails(request)
                    );

                    SecurityContextHolder
                            .getContext()
                            .setAuthentication(authToken);
                }
            }

        } catch (RuntimeException e) {

            /*
             * Invalid / expired / tampered JWT
             * or deleted/deactivated user.
             *
             * Do not expose internal details to the client.
             */
            log.debug(
                    "JWT rejected: {}",
                    e.getClass().getSimpleName()
            );
        }

        filterChain.doFilter(request, response);
    }
}