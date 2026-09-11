package com.bytebattle.security;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.authority.AuthorityUtils;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import org.springframework.web.filter.OncePerRequestFilter;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.util.List;
import java.util.Optional;

@Configuration
public class SecurityConfig {

    private static final String BEARER_PREFIX = "Bearer ";

    // TEMPORARY — remove once Developer 1's real JWT filter is wired in.
    // Reads whatever string is in the Bearer token field and treats it
    // directly as the userId, so Authentication.getName() returns it.
    static class DevFakeAuthFilter extends OncePerRequestFilter {
        @Override
        protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
                                         FilterChain filterChain) throws ServletException, IOException {

            Optional.ofNullable(request.getHeader("Authorization"))
                    .filter(header -> header.startsWith(BEARER_PREFIX))
                    .map(header -> header.substring(BEARER_PREFIX.length()).trim())
                    .filter(userId -> !userId.isBlank())
                    .ifPresent(userId -> {
                        Authentication auth = new UsernamePasswordAuthenticationToken(
                                userId, null, AuthorityUtils.NO_AUTHORITIES);
                        SecurityContextHolder.getContext().setAuthentication(auth);
                    });

            filterChain.doFilter(request, response);
        }
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration config = new CorsConfiguration();
        config.setAllowedOriginPatterns(List.of("*"));   // TEMPORARY — tighten before real production
        config.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "OPTIONS"));
        config.setAllowedHeaders(List.of("*"));

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return source;
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .csrf(csrf -> csrf.disable())
            .cors(cors -> cors.configurationSource(corsConfigurationSource()))
            .authorizeHttpRequests(auth -> auth.anyRequest().permitAll())
            .addFilterBefore(new DevFakeAuthFilter(), UsernamePasswordAuthenticationFilter.class);
        return http.build();
    }
}