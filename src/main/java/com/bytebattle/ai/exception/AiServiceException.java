package com.bytebattle.ai.exception;

/**
 * Raised when the Python AI service is unreachable, times out, or answers with an error.
 * {@code code} is the service's structured error code (or a local one such as AI_UNAVAILABLE /
 * AI_TIMEOUT / AI_DISABLED); {@code status} is the upstream HTTP status (0 when no response).
 */
public class AiServiceException extends RuntimeException {

    private static final long serialVersionUID = 2L;

    private final String code;
    private final int status;

    public AiServiceException(String code, int status, String message) {
        super(message);
        this.code = code;
        this.status = status;
    }

    public AiServiceException(String code, int status, String message, Throwable cause) {
        super(message, cause);
        this.code = code;
        this.status = status;
    }

    public String getCode() {
        return code;
    }

    public int getStatus() {
        return status;
    }
}
