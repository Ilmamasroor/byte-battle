package com.bytebattle.byte_battle_backend.exception;

// Throw this for "this already exists" / state-conflict cases
// (e.g. duplicate email, duplicate LearnerProfile for a user).
public class ConflictException extends RuntimeException {
    public ConflictException(String message) {
        super(message);
    }
}