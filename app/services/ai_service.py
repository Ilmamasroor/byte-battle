from typing import Type, TypeVar

from pydantic import BaseModel

from app.clients.groq_client import GroqClient
from app.clients.llm_client import LLMClient
from app.core.config import settings


llm_client: LLMClient = GroqClient(
    api_key=settings.groq_api_key,
    model=settings.groq_model,
    timeout_seconds=settings.groq_timeout_seconds,
    max_retries=settings.groq_max_retries,
)

MODEL_NAME = settings.groq_model

T = TypeVar("T", bound=BaseModel)


def generate_text(prompt: str) -> str:
    return llm_client.generate_text(prompt)


def generate_json(prompt: str, response_model: Type[T] | None = None) -> dict:
    result = llm_client.generate_json(prompt)

    if response_model is None:
        return result

    validated = response_model.model_validate(result)

    # `source` is useful as internal AI-response metadata, but should not
    # change the existing API payloads consumed by the Spring Boot backend.
    return validated.model_dump(exclude={"source"})


def generate_explanation(concept: str) -> str:
    prompt = f"""
Explain the concept '{concept}' in simple, beginner-friendly language,
in 2-3 sentences.
"""

    return generate_text(prompt)
