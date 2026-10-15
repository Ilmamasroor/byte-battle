import os
from pathlib import Path

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict

# app/core/config.py -> project root is two levels above "core"
ENV_FILE = Path(__file__).resolve().parents[2] / ".env"


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=ENV_FILE,
        env_file_encoding="utf-8",
        extra="ignore",
    )

    # Missing key must not crash import; the LLM layer raises AI_NOT_CONFIGURED
    # lazily when a call is actually made.
    groq_api_key: str = ""
    groq_model: str = "openai/gpt-oss-120b"
    groq_timeout_seconds: float = Field(default=4.0, gt=0)
    groq_max_retries: int = Field(default=1, ge=0)
    byte_dna_weight_previous: float = Field(default=0.7, ge=0.0, le=1.0)

    @property
    def llm_configured(self) -> bool:
        return bool(self.groq_api_key and self.groq_api_key.strip())


def _load() -> Settings:
    try:
        return Settings()
    except Exception:
        # Invalid GROQ_* values: fall back to defaults, never print secrets.
        return Settings.model_construct(
            groq_api_key=os.environ.get("GROQ_API_KEY", ""),
            groq_model="openai/gpt-oss-120b",
            groq_timeout_seconds=4.0,
            groq_max_retries=1,
            byte_dna_weight_previous=0.7,
        )


settings = _load()
