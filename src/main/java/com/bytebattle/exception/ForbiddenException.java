package com.bytebattle.exception;

// Throw this when the user IS authenticated, but isn't allowed
// to do this specific action (e.g. accessing someone else's data).
public class ForbiddenException extends RuntimeException {
    /**
	 * 
	 */
	private static final long serialVersionUID = 1L;

	public ForbiddenException(String message) {
        super(message);
    }
}
