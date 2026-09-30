package com.bytebattle.ai.exception;


public class AiServiceException extends RuntimeException {
    /**
	 * 
	 */
	private static final long serialVersionUID = 1L;

	public AiServiceException(String message, Throwable cause) {
        super(message, cause);
    }
}
