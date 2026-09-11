package com.bytebattle.byte_battle_backend.exception;

// Throw this for generic "the request itself is invalid" cases
// that aren't covered by @Valid annotations (e.g. business rule violations).
public class BadRequestException extends RuntimeException {
    public BadRequestException(String message) {
        super(message);
    }
}