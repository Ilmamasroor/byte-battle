import logging
from typing import Optional, Type, TypeVar

from pydantic import BaseModel, ValidationError

from app.clients.llm_client import LLMClient
from app.core.config import settings
from app.core.exceptions import (
    AI_NOT_CONFIGURED,
    AIBadResponseError,
    AIServiceError,
)

logger = logging.getLogger(__name__)

# Built lazily so importing the app never fails when GROQ_API_KEY is missing.
# Tests (and alternative providers) may replace this attribute directly.
llm_client: Optional[LLMClient] = None

MODEL_NAME = settings.groq_model

T = TypeVar("T", bound=BaseModel)


def is_llm_configured() -> bool:
    return llm_client is not None or settings.llm_configured


def _get_client() -> LLMClient:
    global llm_client
    if llm_client is not None:
        return llm_client
    if not settings.llm_configured:
        raise AIServiceError(
            AI_NOT_CONFIGURED,
            "AI service is not configured: GROQ_API_KEY is missing",
            503,
        )
    from app.clients.groq_client import GroqClient

    llm_client = GroqClient(
        api_key=settings.groq_api_key,
        model=settings.groq_model,
        timeout_seconds=settings.groq_timeout_seconds,
        max_retries=settings.groq_max_retries,
    )
    return llm_client


def generate_text(prompt: str, system: Optional[str] = None) -> str:
    client = _get_client()
    if system is None:
        return client.generate_text(prompt)
    return client.generate_text(prompt, system=system)


def generate_json(
    prompt: str,
    response_model: Type[T] | None = None,
    system: Optional[str] = None,
) -> dict:
    client = _get_client()
    result = client.generate_json(prompt) if system is None else client.generate_json(prompt, system=system)

    if response_model is None:
        return result

    if not isinstance(result, dict):
        raise AIBadResponseError()

    try:
        validated = response_model.model_validate(result)
    except ValidationError as exc:
        logger.warning("LLM response failed validation: %s", response_model.__name__)
        raise AIBadResponseError() from exc

    # `source` is useful as internal AI-response metadata, but should not
    # change the existing API payloads consumed by the Spring Boot backend.
    return validated.model_dump(exclude={"source"})


def generate_explanation(
    concept: str,
    byte_dna: Optional[dict] = None,
    reference: Optional[str] = None,
) -> str:
    from app.core.prompt_safety import SAFETY_SYSTEM, wrap_learner_data, wrap_reference

    parts = [
        "Explain the concept below in simple, beginner-friendly language, in 2-3 sentences.",
        "CONCEPT:",
        wrap_learner_data("concept", concept, 300),
    ]
    if reference:
        parts += [
            "Use ONLY the reference material below as the factual base; do not add facts that are not in it.",
            wrap_reference("canonical", reference),
        ]
    if byte_dna:
        parts += [
            "Adapt tone and examples to this learner profile (preferences only, not facts):",
            wrap_learner_data("learner_profile", byte_dna, 1200),
        ]
    return generate_text("\n".join(parts), system=SAFETY_SYSTEM)
