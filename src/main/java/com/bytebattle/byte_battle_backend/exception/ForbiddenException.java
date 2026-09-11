package com.bytebattle.byte_battle_backend.exception;

// Throw this when the user IS authenticated, but isn't allowed
// to do this specific action (e.g. accessing someone else's data).
public class ForbiddenException extends RuntimeException {
    public ForbiddenException(String message) {
        super(message);
    }
}
