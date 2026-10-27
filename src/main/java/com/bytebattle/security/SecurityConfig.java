package com.bytebattle.security;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.Arrays;
import java.util.List;

@Configuration
@EnableWebSecurity
@EnableMethodSecurity
public class SecurityConfig {

    private static final String ADMIN = "ADMIN";

    // Used to hash passwords before saving to DB, and to check passwords on login
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration config) throws Exception {
        return config.getAuthenticationManager();
    }

    @Bean
    public JwtAuthFilter jwtAuthFilter(JwtUtil jwtUtil, CustomUserDetailsService userDetailsService,
                                       RestAuthenticationEntryPoint entryPoint) {
        return new JwtAuthFilter(jwtUtil, userDetailsService, entryPoint);
    }

    /** The JWT filter must only run inside the Spring Security chain, not as a plain servlet filter. */
    @Bean
    public FilterRegistrationBean<JwtAuthFilter> jwtAuthFilterRegistration(JwtAuthFilter filter) {
        FilterRegistrationBean<JwtAuthFilter> registration = new FilterRegistrationBean<>(filter);
        registration.setEnabled(false);
        return registration;
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource(
            @Value("${bytebattle.cors.allowed-origins:http://localhost:*,http://127.0.0.1:*}") String origins) {
        CorsConfiguration config = new CorsConfiguration();
        List<String> allowed = Arrays.stream(origins.split(","))
                .map(String::trim).filter(s -> !s.isEmpty()).toList();
        // patterns (not exact origins) so Flutter web on any localhost port works: http://localhost:*
        config.setAllowedOriginPatterns(allowed);
        config.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        config.setAllowedHeaders(List.of("Authorization", "Content-Type", "Accept", "ngrok-skip-browser-warning"));
        config.setMaxAge(3600L);
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return source;
    }

    @Bean
    public OnboardingGuardFilter onboardingGuardFilter(OnboardingStatusProvider statusProvider, ApiErrorWriter errorWriter) {
        return new OnboardingGuardFilter(statusProvider, errorWriter);
    }

    @Bean
    public FilterRegistrationBean<OnboardingGuardFilter> onboardingGuardRegistration(OnboardingGuardFilter filter) {
        FilterRegistrationBean<OnboardingGuardFilter> registration = new FilterRegistrationBean<>(filter);
        registration.setEnabled(false);
        return registration;
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http, JwtAuthFilter jwtAuthFilter,
                                                   OnboardingGuardFilter onboardingGuardFilter,
                                                   RestAuthenticationEntryPoint entryPoint,
                                                   RestAccessDeniedHandler accessDeniedHandler) throws Exception {
        http
            .csrf(csrf -> csrf.disable()) // not needed for a stateless JWT API
            .cors(Customizer.withDefaults())
            .sessionManagement(sm -> sm.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .exceptionHandling(eh -> eh
                .authenticationEntryPoint(entryPoint)
                .accessDeniedHandler(accessDeniedHandler))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()
                .requestMatchers("/api/auth/**").permitAll()   // register & login are public
                // learner actions that happen to be POSTs under admin-managed resources
                .requestMatchers(HttpMethod.POST, "/api/battles/*/start").authenticated()
                .requestMatchers(HttpMethod.POST, "/api/coding/challenges/*/submissions").authenticated()
                // content management is ADMIN only
                .requestMatchers(HttpMethod.POST, "/api/battles/**", "/api/coding/challenges/**").hasRole(ADMIN)
                .requestMatchers(HttpMethod.PUT, "/api/battles/**", "/api/coding/challenges/**").hasRole(ADMIN)
                .requestMatchers(HttpMethod.PATCH, "/api/battles/**", "/api/coding/challenges/**").hasRole(ADMIN)
                .requestMatchers(HttpMethod.DELETE, "/api/battles/**", "/api/coding/challenges/**").hasRole(ADMIN)
                .requestMatchers("/api/admin/**").hasRole(ADMIN)
                .anyRequest().authenticated()                   // everything else needs a valid token
            )
            .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class)
            .addFilterAfter(onboardingGuardFilter, JwtAuthFilter.class);

        return http.build();
    }
}
