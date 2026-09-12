package com.bytebattle.security;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class JwtUtilTest {

    private final JwtUtil jwtUtil = new JwtUtil();

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
}
