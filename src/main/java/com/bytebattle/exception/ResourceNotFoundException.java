package com.bytebattle.exception;

/**
 * Throw this whenever something is looked up by ID/email/etc and doesn't exist.
 * Example: throw new ResourceNotFoundException("User not found with id: " + id);
 */
public class ResourceNotFoundException extends RuntimeException {
    /**
	 * 
	 */
	private static final long serialVersionUID = 1L;

	public ResourceNotFoundException(String message) {
        super(message);
    }
}