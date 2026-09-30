package com.bytebattle.exception;

// Throw this for "this already exists" / state-conflict cases
// (e.g. duplicate email, duplicate LearnerProfile for a user).
public class ConflictException extends RuntimeException {
    /**
	 * 
	 */
	private static final long serialVersionUID = 1L;

	public ConflictException(String message) {
        super(message);
    }
}