package com.bytebattle.security.service;

import com.bytebattle.exception.BadRequestException;
import com.bytebattle.exception.ConflictException;
import com.bytebattle.security.dto.AuthResponse;
import com.bytebattle.security.dto.ForgotPasswordRequest;
import com.bytebattle.security.dto.LoginRequest;
import com.bytebattle.security.dto.RegisterRequest;
import com.bytebattle.security.dto.ResetPasswordRequest;
import com.bytebattle.security.entity.JwtUtil;
import com.bytebattle.security.entity.PasswordResetToken;
import com.bytebattle.security.repository.PasswordResetTokenRepository;
import com.bytebattle.user.entity.User;
import com.bytebattle.user.repository.UserRepository;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Base64;
import java.util.HexFormat;
import java.util.List;
import java.util.Locale;

@Service
public class AuthService {

    private static final SecureRandom RANDOM = new SecureRandom();

    // Single source of truth; EmailService text says the same number
    public static final int RESET_TOKEN_MINUTES = 30;

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;
    private final AuthenticationManager authenticationManager;
    private final PasswordResetTokenRepository passwordResetTokenRepository;
    private final EmailService emailService;

    public AuthService(UserRepository userRepository, PasswordEncoder passwordEncoder,
                       JwtUtil jwtUtil, AuthenticationManager authenticationManager,
                       PasswordResetTokenRepository passwordResetTokenRepository,
                       EmailService emailService) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtUtil = jwtUtil;
        this.authenticationManager = authenticationManager;
        this.passwordResetTokenRepository = passwordResetTokenRepository;
        this.emailService = emailService;
    }

    private String normalizeEmail(String email) {
        return email.trim().toLowerCase(Locale.ROOT);
    }

    private AuthResponse toAuthResponse(User user) {
        return new AuthResponse(
                jwtUtil.generateToken(user.getId()),
                user.getId(),
                user.getEmail(),
                user.getName());
    }

    // POST /api/auth/register
    public AuthResponse register(RegisterRequest request) {
        String email = normalizeEmail(request.getEmail());

        if (userRepository.existsByEmail(email)) {
            throw new ConflictException("Email is already registered");
        }

        User user = new User();
        user.setEmail(email);
        user.setName(request.getUsername().trim());
        user.setPasswordHash(passwordEncoder.encode(request.getPassword()));
        user.setRole(User.Role.USER);
        user.setActive(true);

        User saved;
        try {
            saved = userRepository.saveAndFlush(user);
        } catch (DataIntegrityViolationException e) {
            throw new ConflictException("Email is already registered");
        }

        return toAuthResponse(saved);
    }

    // POST /api/auth/login
    // BadCredentialsException / DisabledException are mapped to a generic 401 by GlobalExceptionHandler
    public AuthResponse login(LoginRequest request) {
        String email = normalizeEmail(request.getEmail());

        Authentication auth = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(email, request.getPassword()));

        User user = ((CustomUserDetailsService) auth.getPrincipal()).getUser();
        return toAuthResponse(user);
    }

    // POST /api/auth/forgot-password
    // Always completes silently: the response must not reveal whether the email exists.
    @Transactional
    public void forgotPassword(ForgotPasswordRequest request) {
        String email = normalizeEmail(request.getEmail());

        userRepository.findByEmail(email)
                .filter(user -> Boolean.TRUE.equals(user.getActive()))
                .ifPresent(this::issueResetToken);
    }

    private void issueResetToken(User user) {
        // invalidate older unused tokens so only the newest link works
        List<PasswordResetToken> older = passwordResetTokenRepository.findByUser_IdAndUsedFalse(user.getId());
        older.forEach(t -> t.setUsed(true));
        passwordResetTokenRepository.saveAll(older);

        String rawToken = newToken();

        PasswordResetToken resetToken = new PasswordResetToken();
        resetToken.setUser(user);
        resetToken.setToken(hash(rawToken));   // only the hash is stored
        resetToken.setExpiresAt(Instant.now().plus(RESET_TOKEN_MINUTES, ChronoUnit.MINUTES));
        resetToken.setUsed(false);
        passwordResetTokenRepository.save(resetToken);

        // async; failures are logged inside EmailService, never shown to the caller
        emailService.sendPasswordResetEmail(user.getEmail(), rawToken);
    }

    // POST /api/auth/reset-password
    @Transactional
    public void resetPassword(ResetPasswordRequest request) {
        PasswordResetToken resetToken = passwordResetTokenRepository
                .findByToken(hash(request.getToken().trim()))
                .orElseThrow(() -> new BadRequestException("Invalid or expired reset token"));

        if (Boolean.TRUE.equals(resetToken.getUsed())) {
            throw new BadRequestException("This reset link has already been used");
        }
        if (resetToken.getExpiresAt().isBefore(Instant.now())) {
            throw new BadRequestException("This reset link has expired");
        }

        User user = resetToken.getUser();
        if (!Boolean.TRUE.equals(user.getActive())) {
            throw new BadRequestException("Invalid or expired reset token");
        }

        user.setPasswordHash(passwordEncoder.encode(request.getNewPassword()));
        userRepository.save(user);

        resetToken.setUsed(true);
        passwordResetTokenRepository.save(resetToken);
    }

    private static String newToken() {
        byte[] bytes = new byte[32];
        RANDOM.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    private static String hash(String token) {
        try {
            MessageDigest sha = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(sha.digest(token.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 not available", e);
        }
    }
}