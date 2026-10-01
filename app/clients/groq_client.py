import json
import logging

import groq
from groq import Groq

from app.clients.llm_client import LLMClient
from app.core.exceptions import (
    AI_CONFIGURATION_ERROR,
    AI_INTERNAL_ERROR,
    AI_INVALID_RESPONSE,
    AI_PROVIDER_UNAVAILABLE,
    AI_RATE_LIMITED,
    AI_TIMEOUT,
    AIServiceError,
)

logger = logging.getLogger(__name__)


class GroqClient(LLMClient):
    def __init__(
        self,
        api_key: str,
        model: str,
        timeout_seconds: float,
        max_retries: int,
    ) -> None:
        self._client = Groq(
            api_key=api_key,
            timeout=timeout_seconds,
            max_retries=max_retries,
        )
        self._model = model

    def generate_text(self, prompt: str) -> str:
        try:
            response = self._client.chat.completions.create(
                model=self._model,
                messages=[{"role": "user", "content": prompt}],
            )
        except Exception as exc:
            raise self._to_service_error(exc) from exc

        return self._extract_content(response)

    def generate_json(self, prompt: str) -> dict:
        try:
            response = self._client.chat.completions.create(
                model=self._model,
                messages=[{"role": "user", "content": prompt}],
                response_format={"type": "json_object"},
            )
        except Exception as exc:
            raise self._to_service_error(exc) from exc

        raw_text = self._strip_code_fences(self._extract_content(response))

        try:
            return json.loads(raw_text)
        except json.JSONDecodeError as exc:
            logger.warning("Groq returned invalid JSON")
            raise AIServiceError(
                AI_INVALID_RESPONSE,
                "AI service returned an invalid response",
                502,
            ) from exc

    @staticmethod
    def _extract_content(response) -> str:
        content = None
        if response and getattr(response, "choices", None):
            first_choice = response.choices[0]
            if hasattr(first_choice, "message") and getattr(
                first_choice.message, "content", None
            ):
                content = first_choice.message.content

        if not content:
            logger.warning("Groq returned an empty response")
            raise AIServiceError(
                AI_INVALID_RESPONSE,
                "AI service returned an empty response",
                502,
            )
        return content

    @staticmethod
    def _strip_code_fences(text: str) -> str:
        raw_text = text.strip()
        if raw_text.startswith("```"):
            lines = raw_text.splitlines()
            if lines and lines[0].startswith("```"):
                lines = lines[1:]
            if lines and lines[-1].startswith("```"):
                lines = lines[:-1]
            raw_text = "\n".join(lines).strip()
        return raw_text

    @staticmethod
    def _to_service_error(exc: Exception) -> AIServiceError:
        """Map any Groq failure to a controlled error. Only the exception
        type and status are logged, never the prompt, key or raw message."""
        status_code = getattr(exc, "status_code", None)
        logger.warning(
            "Groq call failed: type=%s status=%s", type(exc).__name__, status_code
        )

        # APITimeoutError is a subclass of APIConnectionError, so check it first
        if isinstance(exc, groq.APITimeoutError):
            return AIServiceError(AI_TIMEOUT, "AI service timed out", 504)

        if isinstance(exc, groq.APIConnectionError):
            return AIServiceError(
                AI_PROVIDER_UNAVAILABLE,
                "AI service is temporarily unavailable",
                502,
            )

        if status_code == 429:
            return AIServiceError(
                AI_RATE_LIMITED,
                "AI service is busy, please try again shortly",
                429,
            )

        if status_code in (401, 403, 404):
            # bad key, no permission, or unknown model: our setup, not the caller's
            return AIServiceError(
                AI_CONFIGURATION_ERROR,
                "AI service is not configured correctly",
                502,
            )

        if isinstance(status_code, int) and status_code >= 500:
            return AIServiceError(
                AI_PROVIDER_UNAVAILABLE,
                "AI service is temporarily unavailable",
                502,
            )

        return AIServiceError(
            AI_INTERNAL_ERROR,
            "AI service could not process the request",
            500,
        )