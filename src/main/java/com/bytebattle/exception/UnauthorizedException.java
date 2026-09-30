package com.bytebattle.exception;

// Throw this when the request has NO valid identity at all
// (different from Forbidden, where identity is known but not allowed).
public class UnauthorizedException extends RuntimeException {
    /**
	 * 
	 */
	private static final long serialVersionUID = 1L;

	public UnauthorizedException(String message) {
        super(message);
    }
}