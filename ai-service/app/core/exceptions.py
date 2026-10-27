AI_CONFIGURATION_ERROR = "AI_CONFIGURATION_ERROR"
AI_NOT_CONFIGURED = "AI_NOT_CONFIGURED"
AI_TIMEOUT = "AI_TIMEOUT"
AI_RATE_LIMITED = "AI_RATE_LIMITED"
AI_PROVIDER_UNAVAILABLE = "AI_PROVIDER_UNAVAILABLE"
AI_BAD_RESPONSE = "AI_BAD_RESPONSE"
# Backwards-compatible alias: an unparseable/invalid LLM response is a bad response.
AI_INVALID_RESPONSE = AI_BAD_RESPONSE
AI_INTERNAL_ERROR = "AI_INTERNAL_ERROR"
AI_UNSUPPORTED_OPERATION = "AI_UNSUPPORTED_OPERATION"
MODEL_LOAD_ERROR = "MODEL_LOAD_ERROR"

# Stable mapping from error code to HTTP status.
STATUS_BY_CODE = {
    AI_TIMEOUT: 504,
    AI_RATE_LIMITED: 429,
    AI_BAD_RESPONSE: 502,
    AI_NOT_CONFIGURED: 503,
    AI_CONFIGURATION_ERROR: 502,
    AI_PROVIDER_UNAVAILABLE: 502,
    AI_INTERNAL_ERROR: 500,
    AI_UNSUPPORTED_OPERATION: 422,
    MODEL_LOAD_ERROR: 500,
}


class AIServiceError(Exception):
    """Controlled error raised by the AI layer. Carries a stable error code
    and a safe message, never raw provider text."""

    def __init__(self, code: str, message: str, status_code: int | None = None) -> None:
        super().__init__(message)
        self.code = code
        self.message = message
        self.status_code = (
            status_code if status_code is not None else STATUS_BY_CODE.get(code, 500)
        )


# Short alias used by newer code.
AiError = AIServiceError


class AIBadResponseError(AIServiceError, ValueError):
    """The LLM answered, but not in the shape we require (502 AI_BAD_RESPONSE).
    Also a ValueError so callers that catch validation problems still work."""

    def __init__(self, message: str = "AI service returned an invalid response") -> None:
        AIServiceError.__init__(self, AI_BAD_RESPONSE, message, 502)
