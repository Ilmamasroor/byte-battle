from pathlib import Path

from pydantic import Field, ValidationError
from pydantic_settings import BaseSettings, SettingsConfigDict

# app/core/config.py -> project root is two levels above "core"
ENV_FILE = Path(__file__).resolve().parents[2] / ".env"


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=ENV_FILE,
        env_file_encoding="utf-8",
        extra="ignore",
    )

    groq_api_key: str = Field(min_length=1)
    groq_model: str = "openai/gpt-oss-120b"
    groq_timeout_seconds: float = Field(default=4.0, gt=0)
    groq_max_retries: int = Field(default=1, ge=0)


try:
    settings = Settings()
except ValidationError:
    # "from None" hides pydantic's detailed output, so nothing sensitive is printed
    raise RuntimeError(
        "AI service configuration error: GROQ_API_KEY is missing or empty, "
        "or another GROQ_* value in .env is invalid."
    ) from None