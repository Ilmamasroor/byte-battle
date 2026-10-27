package com.bytebattle.security;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class JwtUtilTest {

    static final String SECRET = "unit-test-secret-unit-test-secret-1234567890";

    private final JwtUtil jwtUtil = new JwtUtil(SECRET, 60_000L);

    @Test
    void generateToken_producesValidTokenForCorrectEmail() {
        String token = jwtUtil.generateToken("test@example.com");

        assertNotNull(token);
        assertTrue(jwtUtil.isTokenValid(token, "test@example.com"));
    }

    @Test
    void isTokenValid_returnsFalseForWrongEmail() {
        String token = jwtUtil.generateToken("test@example.com");

        assertFalse(jwtUtil.isTokenValid(token, "someone-else@example.com"));
    }

    @Test
    void extractEmail_throwsForMalformedToken() {
        assertThrows(Exception.class, () -> jwtUtil.extractEmail("this-is-not-a-real-token"));
    }

    @Test
    void tokenSignedWithAnotherSecretIsRejected() {
        JwtUtil other = new JwtUtil("another-secret-another-secret-another-secret", 60_000L);
        String foreign = other.generateToken("test@example.com");

        assertThrows(Exception.class, () -> jwtUtil.extractEmail(foreign));
    }

    @Test
    void expiredTokenIsRejected() {
        JwtUtil shortLived = new JwtUtil(SECRET, 1L);
        String token = shortLived.generateToken("test@example.com");
        try {
            Thread.sleep(20);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
        assertThrows(Exception.class, () -> shortLived.isTokenValid(token, "test@example.com"));
    }

    @Test
    void failsFastWhenSecretMissing() {
        IllegalStateException e = assertThrows(IllegalStateException.class, () -> new JwtUtil("", 1000L));
        assertTrue(e.getMessage().contains("JWT_SECRET"));
        assertThrows(IllegalStateException.class, () -> new JwtUtil(null, 1000L));
        assertThrows(IllegalStateException.class, () -> new JwtUtil("   ", 1000L));
    }

    @Test
    void secretLengthIsMeasuredInUtf8Bytes() {
        assertThrows(IllegalStateException.class, () -> new JwtUtil("x".repeat(31), 1000L));
        assertDoesNotThrow(() -> new JwtUtil("x".repeat(32), 1000L));
        // 16 two-byte characters = 32 bytes -> accepted
        assertDoesNotThrow(() -> new JwtUtil("é".repeat(16), 1000L));
    }

    @Test
    void rejectsNonPositiveExpiration() {
        assertThrows(IllegalStateException.class, () -> new JwtUtil(SECRET, 0L));
    }
}
