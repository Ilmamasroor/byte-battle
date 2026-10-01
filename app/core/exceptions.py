AI_CONFIGURATION_ERROR = "AI_CONFIGURATION_ERROR"
AI_TIMEOUT = "AI_TIMEOUT"
AI_RATE_LIMITED = "AI_RATE_LIMITED"
AI_PROVIDER_UNAVAILABLE = "AI_PROVIDER_UNAVAILABLE"
AI_INVALID_RESPONSE = "AI_INVALID_RESPONSE"
AI_INTERNAL_ERROR = "AI_INTERNAL_ERROR"


class AIServiceError(Exception):
    """Controlled error raised by the AI layer. Carries a stable error code
    and a safe message, never raw provider text."""

    def __init__(self, code: str, message: str, status_code: int = 502) -> None:
        super().__init__(message)
        self.code = code
        self.message = message
        self.status_code = status_code