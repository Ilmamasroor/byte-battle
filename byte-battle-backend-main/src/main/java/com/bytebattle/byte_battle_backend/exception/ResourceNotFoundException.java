package com.bytebattle.byte_battle_backend.exception;

/**
 * Throw this whenever something is looked up by ID/email/etc and doesn't exist.
 * Example: throw new ResourceNotFoundException("User not found with id: " + id);
 */
public class ResourceNotFoundException extends RuntimeException {
    public ResourceNotFoundException(String message) {
        super(message);
    }
}